import os, osproc
import httpclient
import json
import strutils
import winlean
import winim/lean
import vars

proc installSpecialK*: void =
    for file in ["dxgi.dll", "dxgi.ini"]: removeFile(gamedir/file)
    discard execCmdEx("taskkill /f /im ResEnforce.exe", options={poDaemon})
    # Download Files.
    var 
        client = newHttpClient()
        r = parseJson(client.getContent("https://api.github.com/repos/SpecialKO/SpecialK/releases/latest"))
        (specialk, archiver, dll) =  (temp/"SpecialK.7z", temp/"7zr.exe", temp/"SpecialK/SpecialK64.dll")
        osdf = documents/"My Mods/SpecialK/Global/osd.ini"
        cfgf = gamedir/"dxgi.ini"
        re = documents/"My Mods/ResEnforce/ResEnforce.exe"
        l: string
    echo "[Mods] Fetching the latest Special K GitHub release..."

    client.downloadFile(r["assets"][0]["browser_download_url"].getStr(), specialk)
    echo "[Mods] Fetching 7-Zip console executable..."
    client.downloadFile("https://www.7-zip.org/a/7zr.exe", archiver)

    discard execCmdEx("$1 x $2 -o\"$3\\SpecialK\" -y" % [archiver, specialk, temp], options={poDaemon})
    copyFile(dll, gamedir/"dxgi.dll")

    # Setup Special K.
    discard execCmdEx("\"$1\" steam://rungameid/1240440" % steamclient, options={poDaemon})
    while true:
        if fileExists(cfgf):
            discard execCmdEx("taskkill /f /im HaloInfinite.exe", options={poDaemon})
            break
    
    # Remove Version Banner.
    var osdc = readFile(osdf).splitLines()
    for i in 0..len(osdc)-1:
        l = osdc[i].strip()
        if l.startsWith("Duration"): osdc[i] = "Duration=0.0"; break
    writeFile(osdf, osdc.join("\n"))

    if fileExists(re):
        echo "[Mods] Starting Resolution Enforcer..."
        discard startProcess(documents/"My Mods/ResEnforce/ResEnforce.exe")

proc installResEnforce: void =
    var 
        sid = execCmdEx("whoami.exe /user /fo csv").output.splitLines()[1].split("\",")[1].strip(chars={'"'}).strip()
        dir = documents/"My Mods/ResEnforce"
        client = newHttpClient()
        r = parseJson(client.getContent("https://api.github.com/repos/Aetopia/ResEnforce/releases/latest"))
        
    discard execCmdEx("taskkill /im /f ResEnforce.exe")
    if not dirExists(dir): createDir(dir)
    echo "[Mods] Fetching the latest Resolution Enforcer GitHub release..."
    client.downloadFile(r["assets"][0]["browser_download_url"].getStr().strip(), dir/"ResEnforce.exe")
    writeFile(temp/"ResEnforce.xml", xml % [sid, dir/"ResEnforce.exe"])
    MessageBox(0, "ZetaConfig will add Resolution Enforcer to startup via Task Scheduler.\nPress OK to add the task.", "ZetaConfig", 0x00000040)
    echo "[Mods] Attempting to prompt and add Resolution Enforcer to Task Scheduler..."
    discard shellExecutew(0, newWideCString("runas"), newWideCString("schtasks.exe"), newWideCString("/Create /XML \"$1\" /tn ResEnforce /f" % [temp / "ResEnforce.xml"]), nil, 0)
    echo "[Mods] Starting Resolution Enforcer..."
    discard startProcess(dir/"ResEnforce.exe")

proc installMods*: void =
    var (sk, re) = (false, false)
    proc consent(msg: string): bool = 
        if MessageBox(0, msg & "\nInstall?", "ZetaConfig", 0x00000004 or 0x00000040) == 6:
            return true
        quit()
    if not fileExists(gamedir/"dxgi.dll") and not fileExists(gamedir/"dxgi.ini"): 
        echo "[Mods] Special K is not installed."
        sk = true
    else: echo "[Mods] Special K is already installed."

    if not fileExists(documents/"My Mods/ResEnforce/ResEnforce.exe"): 
        echo "[Mods] ResEnforce is not installed."
        re = true
    else: echo "[Mods] ResEnforce is already installed."
    
    if sk and re: 
        if consent("Special K and Resolution Enforcer not are installed."):
            installSpecialK()
            installResEnforce()
    elif sk: 
        if consent("Special K is not installed."):
            installSpecialK()
    elif re: 
        if consent("Resolution Enforcer not installed."):
            installResEnforce()