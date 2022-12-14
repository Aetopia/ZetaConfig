{.compile: "Zeta.c".}
{.passl: "-lshcore".}
import json
import os

proc Zeta(width, height: int): void {.importc.}

if isMainModule:
    let 
        cfg = parseJson(readFile(getEnv("LOCALAPPDATA")/"HaloInfinite/Settings/SpecControlSettings.json"))
        w = cfg["spec_control_windowed_display_resolution_x"]["value"].getInt()
        h = cfg["spec_control_windowed_display_resolution_y"]["value"].getInt()
    Zeta(w, h)