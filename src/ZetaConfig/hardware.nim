{.compile: "GetMonitorName.c".}
import os, osproc
import strutils, strformat
import winim/[lean, extra]
import vars

proc GetMonitorName(hwnd: HWND, file: cstring): void {.importc.}

proc isNVIDIA*: bool = 
    const key = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Enum\\PCI"
    var
        msg = " not detected."
        r = false
        keys = execCmdEx(&"reg query \"{key}\"").output.strip(chars={'\n'}).splitLines()
    for l in keys:
        if l.contains("VEN_10DE"):
            msg = " detected."
            r = true
            break
    echo "[Settings] NVIDIA GPU", msg
    return r

proc getGameDisplay* =
    var 
        pid: DWORD
        hproc: HANDLE
        exe: string
        hwnd: HWND
    if not fileExists(gamedir/"ZetaConfig.txt"):
        echo "[Hardware] Detecting which monitor, Halo Infinite launches on..."
        if fileExists(gamedir/"WDMTHook.dll"): moveFile(gamedir/"WDMTHook.dll", gamedir/"WDMTHook.dll.bak")
        discard execCmdEx("\"$1\" steam://rungameid/1240440" % steamclient, options={poDaemon})
        while true:
            exe = newString(MAX_PATH)
            hwnd = GetForegroundWindow()
            GetWindowThreadProcessId(hwnd, &pid)
            hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid)  
            GetModuleFileNameExA(hProc, 0, exe, MAX_PATH)
            CloseHandle(hproc)
            if (extractFilename(exe).toLower().strip(chars={'\0'}) == "haloinfinite.exe"):
                GetMonitorName(hwnd, cstring(gamedir/"ZetaConfig.txt"))
                discard execCmdEx("taskkill /f /im HaloInfinite.exe", options={poDaemon})
                if fileExists(gamedir/"WDMTHook.dll.bak"): moveFile(gamedir/"WDMTHook.dll.bak", gamedir/"WDMTHook.dll")
                echo "[Hardware] Monitor detection success."
                return

proc getDisplayModes*: seq[string] =
    var display = readFile(gamedir/"ZetaConfig.txt")
    var 
        i: int32 = 0
        dms: seq[string]
        dm: string
        devmode: DEVMODE
        add: bool
    devmode.dmSize = sizeof(DEVMODE).WORD
    
    while true:
        if EnumDisplaySettingsEx(display, i, &devmode, EDS_RAWMODE) == 0:
            echo "[Settings] Display Modes: ", dms
            return dms
        dm = fmt"{$devmode.dmPelsWidth}x{$devmode.dmPelsHeight}"
        if dm == "800x600": add = true
        if not dms.contains(dm) and add: dms.add(dm)
        inc(i)