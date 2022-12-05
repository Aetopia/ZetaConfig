import os
import json
import strutils, strformat
import winim/lean
import vars

proc setGameSettings*(dm: seq[string], resscale: string): void =
    var cfg = parseFile(gameconfig)

    for k in [
        "spec_control_minimum_framerate", 
        "spec_control_target_framerate"]: 
        cfg[k].add("value", newJInt(960))

    for k in [
        "spec_control_vsync", 
        "spec_control_window_mode",
        "spec_control_use_cached_window_position"]: 
        cfg[k].add("value", newJInt(0))

    cfg["spec_control_use_cached_window_position"].add("value", newJInt(0))
    cfg["spec_control_window_size"].add("value", newJNull())
    cfg["spec_control_window_position_x"].add("value", newJInt(0))
    cfg["spec_control_window_position_y"].add("value", newJInt(0))
    cfg["spec_control_windowed_display_resolution_x"].add("value", newJInt(dm[0].parseInt))
    cfg["spec_control_windowed_display_resolution_y"].add("value", newJInt(dm[1].parseInt))
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

proc getSettings*: (string, string, string, string) =   
    let 
        skc = readFile(dxgiini).splitLines()

    if not fileExists(wdmt): writeFile(wdmt, "0 0") 
    var dm = readFile(wdmt)
    echo fmt"[Settings] Loaded Setting: Display Mode={dm}"
    
    var
        l, k, v, reflex, cpus, fps: string
        enable, lowlatency, boost, str, verbose: bool

    for i in 0..skc.len-1:
        l = skc[i].strip()
        try: (k, v) = l.split("=")
        except IndexDefect: discard
        (k, v) = (k.strip(), v.strip().toLower())
        if str:
            case k:
                of "Enable": enable = parseBool(v); verbose = true
                of "LowLatency": lowlatency = parseBool(v); verbose = true
                of "LowLatencyBoost": boost = parseBool(v); verbose = true
        if l == "[NVIDIA.Reflex]": str = true

        case k:
            of "OverrideCPUCoreCount": 
                cpus = v
                verbose = true
            of "TargetFPS":
                fps = $(v.strip(chars={'-', ' '}).parseFloat.int)
                verbose = true
        if verbose: echo "[Settings] Loaded Setting: ", l; verbose = false

    if enable:
        if lowlatency and boost: reflex = "On + Boost"
        elif lowlatency: reflex = "On"
        elif boost: reflex = "Boost"
    else: reflex = "Off"
    return (dm.replace(" ", "x"), cpus, reflex, fps)

proc setSettings*(dm: string, reflex: string, cpus: string, fps: string): void =
    var 
        c = readFile(dxgiini).splitLines()
        k, v, l: string
        lowlatency, boost: string
        enable  = "true"
        verbose: bool
        str: bool

    if not fileExists(wdmt): writeFile(wdmt, "0 0") 
    writeFile(wdmt, dm)
    echo fmt"[Settings] Saved Setting: Display Mode={dm}"

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

        case k:
            of "OverrideRes", "ResolutionForMonitor": c[i] = &"{k}=0x0"
            of "RememberResolution", "Fullscreen", "Borderless", "Center", "CatchAltF4": c[i] = &"{k}=false"
            of "OverrideCPUCoreCount": c[i] = fmt"{k}={cpus}"; verbose = true
            of "TargetFPS": c[i] = fmt"{k}={fps}"; verbose = true
            of "AlwaysOnTop": c[i] = &"{k}=0"
            of "PresentationInterval": c[i] = &"{k}=-1"
            of "RenderInBackground": c[i]= &"{k}=true"
            of "XOffset", "YOffset": c[i] = &"{k}=0.0001%"
        if verbose: echo "[Settings] Saved Setting: ", c[i]; verbose = false
    writeFile(dxgiini, c.join("\n"))