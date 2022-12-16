import json
import strutils, strformat
import winim/lean
import vars
import osproc

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

proc setGameSettings*(): void =
    var cfg = parseFile(gameconfig)

    for k in [
        "spec_control_minimum_framerate", 
        "spec_control_target_framerate"]: 
        cfg[k].add("value", newJInt(960))

    for k in [
        "spec_control_vsync", 
        "spec_control_use_cached_window_position"]: 
        cfg[k].add("value", newJInt(0))

    for k in ["spec_control_window_size",
    "spec_control_window_position_x",
    "spec_control_window_position_y"]:
        cfg[k].add("value", newJInt(0))
    cfg["spec_control_use_cached_window_position"].add("value", newJInt(0))
    cfg["spec_control_window_mode"].add("value", newJInt(1))
    cfg["spec_control_resolution_scale"].add("value", newJInt(100))
    cfg["spec_control_sharpening"].add("value", newJInt(100))
    echo "[Settings] Saved Setting: spec_control_resolution_scale=", 100
    writeFile(gameconfig, cfg.pretty(indent=4))

proc setSettings*(reflex: string, cpus: string, fps: string): void =
    var 
        c = readFile(dxgiini).splitLines()
        k, v, l: string
        lowlatency, boost: string
        enable  = "true"
        verbose: bool
        str: bool

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
            of "RememberResolution", "CatchAltF4", "AntialiasLines", "AntialiasContours", "d3d9", "d3d9ex", "OpenGL", "Vulkan": c[i] = &"{k}=false"
            of "OverrideCPUCoreCount": c[i] = fmt"{k}={cpus}"; verbose = true
            of "TargetFPS": c[i] = fmt"{k}={fps}"; verbose = true
            of "AlwaysOnTop": c[i] = &"{k}=1"
            of "PresentationInterval": c[i] = &"{k}=-1"
            of "RenderInBackground", "DisableAlpha", "BypassAltF4Handler": c[i]= &"{k}=true"
        if verbose: echo "[Settings] Saved Setting: ", c[i]; verbose = false
    writeFile(dxgiini, c.join("\n"))