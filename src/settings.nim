import os, osproc
import json
import strutils, strformat
import parsecfg
import winim/lean
import vars

proc isNVIDIA*: bool = 
    const 
        cmd = "reg query \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver\""
    var
        msg = " detected."
        r = true
    if execCmdEx(cmd, options={poDaemon}).exitCode != 0: r = false; msg = " not detected."
    echo "[Settings] NVIDIA GPU", msg
    return r

proc getDisplayModes*: seq[string] =
    var 
        i: int32 = 0
        dms: seq[string]
        dm: string
        devmode: DEVMODE
        add: bool
    devmode.dmSize = sizeof(DEVMODE).WORD
    while true:
        if EnumDisplaySettings(nil, i, &devmode) == 0: echo "[Settings] Display Modes: ", dms; return dms
        dm = fmt"{$devmode.dmPelsWidth}x{$devmode.dmPelsHeight}"
        if dm == "800x600": add = true
        if not dms.contains(dm) and add: dms.add(dm)
        inc(i)

proc setGameSettings*(resscale: string): void =
    var cfg = parseFile(gameconfig)
    for k in ["spec_control_minimum_framerate", "spec_control_target_framerate"]: cfg[k].add("value", newJInt(960))
    for k in ["spec_control_vsync", "spec_control_window_mode"]: cfg[k].add("value", newJInt(0))
    cfg["spec_control_resolution_scale"].add("value", newJInt(resscale.parseInt))
    cfg["spec_control_sharpening"].add("value", newJInt(100))
    echo "[Settings] Saved Setting: spec_control_resolution_scale=", resscale
    writeFile(gameconfig, cfg.pretty(indent=4))      

proc getGameSettings*: string =
    var 
        cfg = parseFile(gameconfig)
        r: string
    r = $(cfg["spec_control_resolution_scale"]["value"].getInt())
    echo "[Settings] Loaded Setting: spec_control_resolution_scale=", r
    return r

proc getSKSettings*: (string, string, string, string) =   
    let c = readFile(dxgiini).splitLines()
    var
        l, k, v, reflex, cpus, fps: string
        res: string
        enable, lowlatency, boost, str, verbose: bool

    for i in 0..c.len-1:
        l = c[i].strip()
        if str:
            try: (k, v) = l.split("=")
            except IndexDefect: discard
            (k, v) = (k.strip(), v.strip().toLower())
            case k:
                of "Enable": enable = parseBool(v); verbose = true
                of "LowLatency": lowlatency = parseBool(v); verbose = true
                of "LowLatencyBoost": boost = parseBool(v); verbose = true
        if l == "[NVIDIA.Reflex]": str = true

        if l.startsWith("OverrideRes"):
            res = l.split("=")[1].strip(); verbose = true
        elif l.startsWith("OverrideCPUCoreCount"):
            cpus = l.split("=")[1].strip(); verbose = true
        elif l.startsWith("TargetFPS"):
            fps = $(l.split("=")[1].strip(chars={'-', ' '}).parseFloat.int); verbose = true
        if verbose: echo "[Settings] Loaded Setting: ", l; verbose = false

    if enable:
        if lowlatency and boost: reflex = "On + Boost"
        elif lowlatency: reflex = "On"
        elif boost: reflex = "Boost"
    else: reflex = "Off"
    return (res, cpus, reflex, fps)

proc setSKSettings*(res: string, reflex: string, cpus: string, fps: string, native: bool): void =
    let cfg = documents/"My Mods/ResEnforce/Options.ini"
    var 
        c = readFile(dxgiini).splitLines()
        k, v, l: string
        lowlatency, boost: string
        (enable, alwaysontop)  = ("true", "1")
        verbose: bool
        str: bool
    
    if native: alwaysontop = "0"

    if not fileExists(cfg): writeFile(cfg, "") 
    var f = loadConfig(cfg)
    f.setSectionKey("Profiles", "HaloInfinite.exe", res)
    f.writeConfig(cfg)

    case reflex:
        of "Off": (enable, lowlatency, boost) = ("false", "false", "false")
        of "On": (lowlatency, boost) = ("true", "false")
        of "On + Boost": (lowlatency, boost) = ("true", "true")
        of "Boost": (lowlatency, boost) = ("false", "true")

    for i in 0..c.len-1:
        l = c[i].strip()
        try: (k, v) = l.split("=")
        except IndexDefect: discard
        (k, v) = (k.strip(), v.strip().toLower())
        if str:
            case k:
                of "Enable": c[i] = fmt"Enable={enable}"; verbose = true
                of "LowLatency": c[i] = fmt"LowLatency={lowlatency}"; verbose = true
                of "LowLatencyBoost": c[i] = fmt"LowLatencyBoost={boost}"; verbose = true
        if l == "[NVIDIA.Reflex]": str = true

        if l.startsWith("OverrideRes"): 
            c[i] = fmt"OverrideRes={res}"; verbose = true
        elif l.startsWith("OverrideCPUCoreCount"): 
            c[i] = fmt"OverrideCPUCoreCount={cpus}"; verbose = true
        elif l.startsWith("TargetFPS"): 
            c[i] = fmt"TargetFPS={fps}"; verbose = true
        elif l.startsWith("ResolutionForMonitor"):
            c[i] = "ResolutionForMonitor=0x0"
        elif k in ["Borderless", "Center", "RenderInBackground"]: c[i] = &"{k}=true"
        elif k in ["RememberResolution", "Fullscreen"]: c[i] = &"{k}=false"
        elif k in ["XOffset", "YOffset"]: c[i] = &"{k}=0.0001%"
        elif k == "AlwaysOnTop": c[i] = &"AlwaysOnTop={alwaysontop}"
        elif k == "PresentationInterval": c[i] = "PresentationInterval=-1"
        if verbose: echo "[Settings] Saved Setting: ", c[i]; verbose = false
    writeFile(dxgiini, c.join("\n"))