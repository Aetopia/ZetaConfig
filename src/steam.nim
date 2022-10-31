# Steam related Functions
import os, osproc
import strutils
import winim/lean

proc getSteamPath* : string =
    # Fetches the Steam installation directory.
    var 
        muicache = execCmdEx("reg query \"HKEY_CLASSES_ROOT\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\MuiCache\" /s", options={poDaemon})
        protocol = execCmdEx("reg query \"HKEY_CLASSES_ROOT\\steam\\Shell\\Open\\Command\" /ve /s", options={poDaemon})
        n, d, l, p: string
        output: seq[string]

    if muicache.exitCode == 0:
        echo "[Steam] Attempting to locate Steam installation directory using MUICache..."
        output = muicache.output.strip(chars={'\n'}).splitlines()
        for i in 0..len(output)-1:
            l = output[i].strip()
            if not (l.startsWith("HKEY") or l.startsWith("LangID")):
                try:
                    (n, d) = l.split("REG_SZ")
                    (n, d) = (n.strip(), d.strip())
                    if d in ["Steam", "Valve Corporation"]:
                        p = splitPath(n.split(".FriendlyAppName")[0].split(".ApplicationCompany")[0].strip())[0]
                        echo "[Steam] Found Steam installation directory: " & p
                        return p
                except IndexDefect: discard

    elif protocol.exitCode == 0:
        echo "[Steam] Attempting to locate Steam installation directory using the Steam browser protocol..."
        output = protocol.output.strip(chars={'\n'}).splitlines()
        for i in 0..len(output)-1:
            l = output[i].strip()
            if not l.startsWith("HKEY"):
                try:
                    (n, d) = l.split("REG_SZ")
                    p = splitPath(d.strip().split("\" -")[0].strip(chars={'"', ' '}))[0]
                    echo "Steam: Found Steam installation directory: " & p
                    return p
                except IndexDefect: discard
    MessageBox(0, "Could not find Steam installation directory.\nMUI Cache & Steam Browser Protocol are not available!", "ZetaConfig", MB_ICONERROR)
    quit(1)
    
proc getSteamLibraryFolders* : seq[string] =
    var 
        libs = getSteamPath() / "config/libraryfolders.vdf"
        folders: seq[string]
        c = readFile(libs).splitLines()
    for i in c:
        var l = i.strip()
        if l.startsWith("\"path\""):
            folders.add(l.split("\"path\"")[1].strip().strip(chars={'"'}).replace("\\\\", "\\"))
    return folders

proc getSteamGameInstallDir*(game: string): string =
    var 
        folders = getSteamLibraryFolders()
        installdir: string
    for folder in folders:
        installdir = folder/"steamapps/common"/game.strip()
        echo "[Steam] Checking: " & installdir
        if dirExists(installdir): echo "[Steam] Found: " & installdir; return installdir
    MessageBox(0, "Failed to find Game Directory!", "ZetaConfig", 0x00000010)
    quit(1)
