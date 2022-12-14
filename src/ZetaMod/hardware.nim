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
    echo "[Hardware] NVIDIA GPU", msg
    return r

proc getGameMonitor* =
    var 
        pid: DWORD
        hproc: HANDLE
        exe: string
        hwnd: HWND
    if not fileExists(temp/"ZetaMod.txt"):
        echo "[Hardware] Detecting which monitor, Halo Infinite launches on..."
        if fileExists(gamedir/"Zeta.dll"): moveFile(gamedir/"Zeta.dll", gamedir/"Zeta.dll.bak")
        discard execCmdEx("\"$1\" steam://rungameid/1240440" % steamclient, options={poDaemon})
        while true:
            exe = newString(MAX_PATH)
            hwnd = GetForegroundWindow()
            GetWindowThreadProcessId(hwnd, &pid)
            hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid)  
            GetModuleFileNameExA(hProc, 0, exe, MAX_PATH)
            CloseHandle(hproc)
            if (extractFilename(exe).toLower().strip(chars={'\0'}) == "haloinfinite.exe"):
                GetMonitorName(hwnd, cstring(temp/"ZetaMod.txt"))
                discard execCmdEx("taskkill /f /im HaloInfinite.exe", options={poDaemon})
                if fileExists(gamedir/"Zeta.dll.bak"): moveFile(gamedir/"Zeta.dll.bak", gamedir/"Zeta.dll")
                echo "[Hardware] Monitor detection success."
                return
            sleep(1)

proc getCurrentDM*: (int, int) =
    var dm: DEVMODE
    dm.dmSize = sizeof(DEVMODE).WORD
    while (EnumDisplaySettings(readFile(temp/"ZetaMod.txt"), ENUM_CURRENT_SETTINGS, &dm) == 0):
        discard tryRemoveFile(temp/"ZetaMod.txt")
        getGameMonitor()
    return (dm.dmPelsWidth.int, dm.dmPelsHeight.int)

            