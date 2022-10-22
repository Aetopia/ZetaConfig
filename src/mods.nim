import os, osproc
import httpclient
import json
import strutils
import winlean
import winim/lean
import vars

proc installSpecialK*: void =
    for file in [gamedir/"dxgi.dll", gamedir/"dxgi.ini"]: removeFile(file)
    discard execCmdEx("taskkill /f /im ResEnforce.exe")
    # Download Files.
    var 
        client = newHttpClient()
        r = parseJson(client.getContent("https://api.github.com/repos/SpecialKO/SpecialK/releases/latest"))
        (specialk, archiver, dll) =  (temp/"SpecialK.7z", temp/"7zr.exe", temp/"SpecialK/SpecialK64.dll")
        osdf = documents/"My Mods/SpecialK/Global/osd.ini"
        cfgf = gamedir/"dxgi.ini"
        re = documents/"My Mods/ResEnforce/ResEnforce.exe"
    client.downloadFile(r["assets"][0]["browser_download_url"].getStr(), specialk)
    client.downloadFile("https://www.7-zip.org/a/7zr.exe", archiver)

    discard execCmdEx("$1 x $2 -o\"$3\\SpecialK\" -y" % [archiver, specialk, temp])
    copyFile(dll, gamedir/"dxgi.dll")

    # Setup Special K.
    discard execCmd("\"$1\" steam://rungameid/1240440" % [steamclient])
    while true:
        if fileExists(cfgf):
            discard execCmdEx("taskkill /f /im HaloInfinite.exe")
            break
    
    # Remove Version Banner.
    var osdc = readFile(osdf).splitLines()
    for i in 0..len(osdc)-1:
        var l = osdc[i].strip()
        if l.startsWith("Duration"):
            osdc[i] = "Duration=0.0"; break
    writeFile(osdf, osdc.join("\n"))


    # Setup Config.
    var cfgc = readFile(cfgf).splitLines()
    for i in 0..len(cfgc)-1:
        var l = cfgc[i].strip()
        var key = l.split("=")[0].strip()
        if key in ["Borderless", "Center", "RenderInBackground"]: cfgc[i] = "$1=true" % [key]
        elif key in ["XOffset", "YOffset"]: cfgc[i] = "$1=0.0001%" % [key]
        elif key == "AlwaysOnTop": cfgc[i] = "AlwaysOnTop=1"
    writeFile(cfgf, cfgc.join("\n"))
    if fileExists(re):
        discard startProcess(documents/"My Mods/ResEnforce/ResEnforce.exe")

proc installResEnforce: void =
    discard execCmdEx("taskkill /im /f ResEnforce.exe")
    var 
        sid = execCmdEx("whoami.exe /user /fo csv").output.splitLines()[1].split("\",")[1].strip(chars={'"'}).strip()
        dir = documents/"My Mods/ResEnforce"
        client = newHttpClient()
        r = parseJson(client.getContent("https://api.github.com/repos/Aetopia/ResEnforce/releases/latest"))
    if not dirExists(dir): createDir(dir)
    client.downloadFile(r["assets"][0]["browser_download_url"].getStr().strip(), dir/"ResEnforce.exe")
    writeFile(temp/"ResEnforce.xml", xml % [sid, dir/"ResEnforce.exe"])
    MessageBox(0, "ZetaConfig will add Resolution Enforcer to startup via Task Scheduler.\nPress OK to add the task.", "ZetaConfig", 0x00000040)
    discard shellExecutew(0, newWideCString("runas"), newWideCString("schtasks.exe"), newWideCString("/Create /XML \"$1\" /tn ResEnforce /f" % [temp / "ResEnforce.xml"]), nil, 0)
    discard startProcess(dir/"ResEnforce.exe")

proc installMods*: void =
    var (sk, re) = (false, false)
    proc consent(msg: string): bool = 
        if MessageBox(0, msg & "\nInstall?", "ZetaConfig", 0x00000004 or 0x00000040) == 6:
            return true
        quit()
    if not fileExists(gamedir/"dxgi.dll") and not fileExists(gamedir/"dxgi.ini"): sk = true
    if not fileExists(documents/"My Mods/ResEnforce/ResEnforce.exe"): re = true
    
    if sk and re: 
        if consent("Special K and Resolution Enforcer not are installed."):
            installSpecialK()
            installResEnforce()
    elif sk: 
        if consent("Special K not installed."):
            installSpecialK()
    elif re: 
        if consent("Resolution Enforcer not installed."):
            installResEnforce()