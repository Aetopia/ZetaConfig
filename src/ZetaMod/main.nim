import mods
import settings
import hardware

if isMainModule:
    var reflex = "Boost"
    if not isNVIDIA(): reflex = "Off"
    getGameMonitor()
    setGameSettings(100, getCurrentDM())
    installMods()
    setSettings(reflex, "4", "0")