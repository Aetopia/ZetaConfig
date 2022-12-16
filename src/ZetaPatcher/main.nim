import mods
import settings
import winim/lean

if isMainModule:
    var reflex = "Boost"
    if not isNVIDIA(): reflex = "Off"
    setGameSettings()
    installMods()
    setSettings(reflex, "4", "0")
    MessageBox(GetConsoleWindow(), "Special K & Zeta have configured and installed!", "ZetaPatcher", MB_ICONINFORMATION)