# Steam related Functions
import os, osproc
import strutils
import winim/lean

proc getSteamPath* : string =
    # Fetches the Steam installation directory.
    var output: string
    let cmd = execCmdEx("reg query \"$1\" /d /f \"Steam\"" % ["HKCR\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\MuiCache"])
    if cmd.exitCode == 0:
        output = cmd.output
    else:
        raise newException(Exception, "Failed to fetch Steam installation directory.")
    for i in output.splitLines():
        let l = i.strip()
        if l != "" and not l.startsWith("End") and not l.startsWith("HKEY"): 
            return splitPath(l.split(".FriendlyAppName")[0].strip())[0]
    
proc getSteamLibraryFolders* : seq[string] =
    let libs = getSteamPath() / "config/libraryfolders.vdf"
    var folders: seq[string]
    var f = open(libs, fmRead)
    var c = f.readAll().splitLines()
    f.close()
    for i in c:
        let l = i.strip()
        if l.startsWith("\"path\""):
            folders.add(l.split("\"path\"")[1].strip().strip(chars={'"'}).replace("\\\\", "\\"))
    return folders

proc getSteamGameInstallDir*(game: string): string =
    var folders = getSteamLibraryFolders()
    for folder in folders:
        var installdir = folder/"steamapps/common"/game.strip()
        if dirExists(installdir): return installdir
    discard MessageBox(0, "Failed to find Game Directory!", "ZetaConfig", 0x00000010)
    quit()