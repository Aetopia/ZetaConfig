# Steam related Functions
import os, osproc
import strutils
import winim/lean

proc getSteamPath* : string =
    # Fetches the Steam installation directory.
    const msg = "[Steam] Locating Steam Installation Directory:"
    let 
        muicache = execCmdEx("reg query \"HKEY_CLASSES_ROOT\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\MuiCache\" /s", options={poDaemon})
        protocol = execCmdEx("reg query \"HKEY_CLASSES_ROOT\\steam\\Shell\\Open\\Command\" /ve /s", options={poDaemon})
    var 
        n, d, l, p: string
        output: seq[string]
    
    if muicache.exitCode == 0:
        echo msg, " MUICache"
        output = muicache.output.strip(chars={'\n'}).splitlines()
        for i in 0..len(output)-1:
            l = output[i].strip()
            if not (l.startsWith("HKEY") or l.startsWith("LangID")):
                try:
                    (n, d) = l.split("REG_SZ")
                    (n, d) = (n.strip(), d.strip())
                    if d in ["Steam", "Valve Corporation"]:
                        p = splitPath(n.split(".FriendlyAppName")[0].split(".ApplicationCompany")[0].strip())[0]
                except IndexDefect: discard

    if protocol.exitCode == 0:
        echo msg, " Steam Browser Protocol"
        output = protocol.output.strip(chars={'\n'}).splitlines()
        for i in 0..len(output)-1:
            l = output[i].strip()
            if not l.startsWith("HKEY"):
                try:
                    (n, d) = l.split("REG_SZ")
                    p = splitPath(d.strip().split("\" -")[0].strip(chars={'"', ' '}))[0]
                except IndexDefect: discard

    if p != "":
        echo "[Steam] Found Steam Installation Directory: " & p
        return p
    MessageBox(0, "Could not find Steam installation directory.\nMUI Cache & Steam Browser Protocol are not available!", "ZetaConfig", MB_ICONERROR)
    quit(1)
    
proc getSteamLibraryFolders*(steampath: string = getSteamPath()) : seq[string] =
    let 
        libs = steampath / "config/libraryfolders.vdf"
        c = readFile(libs).splitLines()
    var folders: seq[string]

    for i in c:
        var l = i.strip()
        if l.startsWith("\"path\""):
            folders.add(l.split("\"path\"")[1].strip().strip(chars={'"'}).replace("\\\\", "\\"))
    return folders

proc getSteamGameInstallDir*(game: string, steampath: string = getSteamPath()): string = 
    let folders = getSteamLibraryFolders(steampath)
    var installdir: string
    for folder in folders:
        installdir = folder/"steamapps/common"/game.strip()
        if dirExists(installdir): echo "[Steam] Found Game Installation Directory: " & installdir; return installdir
    MessageBox(0, "Failed to find Game Directory!", "ZetaConfig", 0x00000010)
    quit(1)
