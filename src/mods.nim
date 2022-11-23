import os, osproc
import json
import strutils
import winim/lean
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
            writeFile(dxgiini, readFile(dxgiini) & bwdmthook)
            break

    # Remove Version Banner.
    var osdc = readFile(osdf).splitLines()
    for i in 0..osdc.len-1:
        let l = osdc[i].strip()
        if l.startsWith("Duration"): osdc[i] = "Duration=0.0"; break
    writeFile(osdf, osdc.join("\n"))

    echo "[Mods] Special K has been installed!"

proc installBWDMT*: void =
    let 
        r = parseJson(execCmdEx("curl.exe \"https://api.github.com/repos/Aetopia/Borderless-Window-Display-Mode-Tool/releases/latest\"", options={poDaemon}).output)
        fs = ["BWDMT.exe", "BWDMTHook.dll"]
    echo "[Mods] Fetching the latest Borderless Window Display Mode Tool GitHub release..."
    for i in 0..fs.len-1:
        downloadFile(r["assets"][i]["browser_download_url"].getStr().strip(), gamedir/fs[i])
    writeFile(bwdmt, "0x0")
    echo "[Mods] Borderless Window Display Mode Tool has been installed!"

proc installMods*: void =
    var (issk, isbwdmt) = (false, false)
    proc consent(msg: string): bool = 
        if MessageBox(0, msg & "\nInstall?", "ZetaConfig", 0x00000004 or 0x00000040) == 6:
            return true
        quit(0)
    if not fileExists(gamedir/"dxgi.dll") or not fileExists(gamedir/"dxgi.ini"): 
        echo "[Mods] Special K is not installed."
        issk = true
    else: echo "[Mods] Special K is installed."

    if not fileExists(gamedir/"BWDMT.exe") or not fileExists(gamedir/"BWDMTHook.dll"): 
        echo "[Mods] Borderless Window Display Mode Tool is not installed."
        isbwdmt = true
    else: echo "[Mods] Borderless Window Display Mode Tool is installed."
    
    if issk and isbwdmt: 
        if consent("Special K and Borderless Window Display Mode Tool not are installed."):
            installSpecialK()
            installBWDMT()
    elif issk: 
        if consent("Special K is not installed."):
            installSpecialK()
    elif isbwdmt: 
        if consent("Borderless Window Display Mode Tool is not installed."):
            installBWDMT()

