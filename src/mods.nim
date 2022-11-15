import os, osproc
import json
import strutils
import winim/[lean, shell]
import vars

proc downloadFile(url: string, file: string): void = 
    discard execCmdEx("curl.exe -Ls \"$1\" -o \"$2\"" % [url, file], options={poDaemon})

proc installSpecialK*: void =
    for file in ["dxgi.dll", "dxgi.ini"]: removeFile(gamedir/file)
    discard execCmdEx("taskkill /f /im ResEnforce.exe", options={poDaemon})
    # Download Files.
    let 
        r = parseJson(execCmdEx("curl.exe \"https://api.github.com/repos/SpecialKO/SpecialK/releases/latest\"", options={poDaemon}).output)
        (specialk, archiver, dll) =  (temp/"SpecialK.7z", temp/"7zr.exe", temp/"SpecialK/SpecialK64.dll")
        osdf = documents/"My Mods/SpecialK/Global/osd.ini"

    echo "[Mods] Fetching the latest Special K GitHub release..."

    downloadFile(r["assets"][0]["browser_download_url"].getStr(), specialk)
    echo "[Mods] Fetching 7-Zip console executable..."
    downloadFile("https://www.7-zip.org/a/7zr.exe", archiver)

    discard execCmdEx("$1 x $2 -o\"$3\\SpecialK\" -y" % [archiver, specialk, temp], options={poDaemon})
    copyFile(dll, gamedir/"dxgi.dll")

    # Setup Special K.
    discard execCmdEx("\"$1\" steam://rungameid/1240440" % steamclient, options={poDaemon})
    while true:
        if fileExists(dxgiini):
            discard execCmdEx("taskkill /f /im HaloInfinite.exe", options={poDaemon})
            break
    
    # Remove Version Banner.
    var osdc = readFile(osdf).splitLines()
    for i in 0..len(osdc)-1:
        let l = osdc[i].strip()
        if l.startsWith("Duration"): osdc[i] = "Duration=0.0"; break
    writeFile(osdf, osdc.join("\n"))

    if fileExists(re):
        echo "[Mods] Starting Resolution Enforcer..."
        discard startProcess(documents/"My Mods/ResEnforce/ResEnforce.exe")

proc installResEnforce: void =
    let 
        sid = execCmdEx("whoami.exe /user /fo csv").output.splitLines()[1].split("\",")[1].strip(chars={'"'}).strip()
        dir = splitPath(re)[0]
        r = parseJson(execCmdEx("curl.exe \"https://api.github.com/repos/Aetopia/ResEnforce/releases/latest\"", options={poDaemon}).output)
        
    discard execCmdEx("taskkill /im /f ResEnforce.exe")
    if not dirExists(dir): createDir(dir)
    echo "[Mods] Fetching the latest Resolution Enforcer GitHub release..."
    downloadFile(r["assets"][0]["browser_download_url"].getStr().strip(), dir/"ResEnforce.exe")
    writeFile(temp/"ResEnforce.xml", xml % [sid, dir/"ResEnforce.exe"])
    MessageBox(0, "ZetaConfig will add Resolution Enforcer to startup via Task Scheduler.\nPress OK to add the task.", "ZetaConfig", 0x00000040)
    echo "[Mods] Attempting to prompt and add Resolution Enforcer to Task Scheduler..."
    discard ShellExecuteW(0, "runas", "schtasks.exe", "/Create /XML \"$1\" /tn ResEnforce /f" % [temp/"ResEnforce.xml"], nil, 0)
    echo "[Mods] Starting Resolution Enforcer..."

    discard startProcess(re)

proc installMods*: void =
    var (issk, isre) = (false, false)
    proc consent(msg: string): bool = 
        if MessageBox(0, msg & "\nInstall?", "ZetaConfig", 0x00000004 or 0x00000040) == 6:
            return true
        quit()
    if not fileExists(gamedir/"dxgi.dll") or not fileExists(gamedir/"dxgi.ini"): 
        echo "[Mods] Special K is not installed."
        issk = true
    else: echo "[Mods] Special K is installed."

    if not fileExists(documents/"My Mods/ResEnforce/ResEnforce.exe"): 
        echo "[Mods] ResEnforce is not installed."
        isre = true
    else: echo "[Mods] ResEnforce is installed."
    
    if issk and isre: 
        if consent("Special K and Resolution Enforcer not are installed."):
            installSpecialK()
            installResEnforce()
    elif issk: 
        if consent("Special K is not installed."):
            installSpecialK()
    elif isre: 
        if consent("Resolution Enforcer not installed."):
            installResEnforce()