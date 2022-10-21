import os
import json
import strutils
import parsecfg
import winim/lean
import vars

proc getDisplayModes*: seq[string] =
    var 
        i: int32 = 0
        dms: seq[string]
    while true:
        var devmode: DEVMODEW    
        devmode.dmSize = sizeof(DEVMODEW).WORD
        if EnumDisplaySettings(nil, i, addr devmode) == 0: return dms
        var dm = "$1x$2" % [$devmode.dmPelsWidth, $devmode.dmPelsHeight]
        if not dms.contains(dm): dms.add(dm)
        inc(i)

proc setGameSettings*(resscale: string): void =
    var 
        cfg = parseFile(gameconfig)
        val = resscale.parseInt
    if val notin 50..100: val = 100
    for k in ["spec_control_minimum_framerate", "spec_control_target_framerate"]: cfg[k].add("value", newJInt(960))
    for k in ["spec_control_vsync", "spec_control_window_mode"]: cfg[k].add("value", newJInt(0))
    cfg["spec_control_resolution_scale"].add("value", newJInt(val))
    writeFile(gameconfig, cfg.pretty(indent=4))      

proc getGameSettings*: string =
    var cfg = parseFile(gameconfig)
    return $(cfg["spec_control_resolution_scale"]["value"].getInt())

proc getSKSettings*: (string, string, string, string) =   
    var 
        c = readFile(gamedir/"dxgi.ini").splitLines()
        k, v, reflex, cpus, fps: string
        res: string
        enable, lowlatency, boost, str: bool

    for l in c:
        if str:
            try: (k, v) = l.split("=")
            except IndexDefect: discard
            (k, v) = (k.strip(), v.strip().toLower())
            case k:
                of "Enable": enable = parseBool(v)
                of "LowLatency": lowlatency = parseBool(v)
                of "LowLatencyBoost": boost = parseBool(v)
        if l.strip() == "[NVIDIA.Reflex]": str = true

        if l.strip().startsWith("OverrideRes"):
            res = l.split("=")[1].strip()
        elif l.strip().startsWith("OverrideCPUCoreCount"):
            cpus = l.split("=")[1].strip()
        elif l.strip().startsWith("TargetFPS"):
            fps = $(l.split("=")[1].strip(chars={'-', ' '}).parseFloat.int)

    if enable:
        if lowlatency and boost: reflex = "On + Boost"
        elif lowlatency: reflex = "On"
        elif boost: reflex = "Boost"
    else: reflex = "Off"
    return (res, cpus, reflex, fps)

proc setSKSettings*(res: string, reflex: string, cpus: string, fps: string): void =
    var 
        cfg = documents/"My Mods/ResEnforce/Options.ini"
        c = readFile(gamedir/"dxgi.ini").splitLines()
        k, v: string
        lowlatency, boost: string
        enable = "true"
        str: bool

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
        var l = c[i].strip()
        if str:
            try: (k, v) = l.split("=")
            except IndexDefect: discard
            (k, v) = (k.strip(), v.strip().toLower())
            case k:
                of "Enable": c[i] = "Enable=$1" % [enable]
                of "LowLatency": c[i] = "LowLatency=$1" % [lowlatency]
                of "LowLatencyBoost": c[i] = "LowLatencyBoost=$1" % [boost]
        if l == "[NVIDIA.Reflex]": str = true

        if l.startsWith("OverrideRes"): 
            c[i] = "OverrideRes=$1" % res
        elif l.strip().startsWith("OverrideCPUCoreCount"): 
            c[i] = "OverrideCPUCoreCount=$1" % cpus
        elif l.strip().startsWith("TargetFPS"): 
            c[i] = "TargetFPS=$1" % fps
    writeFile(gamedir/"dxgi.ini", c.join("\n"))