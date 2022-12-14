import mods
import settings
import hardware
import winim/lean

if isMainModule:
    var reflex = "Boost"
    if not isNVIDIA(): reflex = "Off"
    getGameMonitor()
    setGameSettings(100, getCurrentDM())
    installMods()
    setSettings(reflex, "4", "0")
    MessageBox(GetConsoleWindow(), "Special K & Zeta have configured and installed!", "ZetaMod", MB_ICONINFORMATION)