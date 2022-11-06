import wNim/[wApp, wFrame, wPanel, wStaticBox, wStaticText, wSpinCtrl, wComboBox, wButton, wMessageDialog]
import winim/lean
import strutils, sequtils
import os, osproc
import mods, settings, vars
const version = "v1.0.0 Pre-Release 3"

if isMainModule:
    if fileExists(localappdata/"Packages\\Microsoft.254428597CFE2_8wekyb3d8bbwe\\LocalCache\\Local\\HaloInfinite\\Settings\\SpecControlSettings.json"):
        MessageBox(0, "Halo Infinite has been installed via the Microsoft Store.\nZetaConfig only supports the Steam version of the game.", "ZetaConfig", MB_ICONERROR)
        quit(1)
    installMods()

    # Settings
    var
        (res, cpus, reflex, fps) = getSKSettings()
        resscale = getGameSettings()
        dms = getDisplayModes()
        cpusopts: seq[string]
        native: bool

    for cpu in toSeq(0..countProcessors()):
        if cpu mod 2 == 0 and cpu >= 4: cpusopts.add(intToStr(cpu))
    if resscale.parseInt notin 50..100: resscale = "100" 
    if res notin dms: res = dms[dms.len-1]
    if cpus notin cpusopts: cpus = cpusopts[cpusopts.len-1]
    if fps.parseInt notin 0..960: fps = "0"

    # GUI 
    let 
        app = App(wPerMonitorDpiAware)
        frame = Frame(title="ZetaConfig $1" % version, style=wSystemMenu, size=(400, 300))
        box = frame.Panel().StaticBox(label="Settings", pos=(7, 0), size=(380, 265))
        rs = box.SpinCtrl(pos=(100, 0), style=wSpCenter or wSpArrowKeys)
        dm = box.ComboBox(size=(120, 23), pos=(100, 34), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=dms, value=res)
        scc = box.ComboBox(size=(120, 23), pos=(100, 68), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=cpusopts, value=cpus)
        nvr = box.ComboBox(size=(120, 23), pos=(100, 102), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=["Off", "On", "Boost", "On + Boost"], value=reflex)
        fpslimit = box.SpinCtrl(pos=(100, 137), style=wSpCenter or wSpArrowKeys)
        save = box.Button(label="Save", pos=(269, 208))
        about = box.Button(label="?", pos=(0, 208), size=(26, 26))
        
    if not isNVIDIA(): nvr.clear(); nvr.append("Off"); nvr.setSelection(0)
    rs.setValue(resscale)
    rs.setRange(50..100)
    fpslimit.setValue(fps)
    fpslimit.setRange(0..960)

    box.Button(size=(-1, -1), pos=(-1, -1)).setFocus()
    box.StaticText(label="Resolution Scale", pos=(0, 3))
    box.StaticText(label="Display Mode", pos=(0, 37))
    box.StaticText(label="Spoof CPU Cores", pos=(0, 71))
    box.StaticText(label="NVIDIA Reflex", pos=(0, 106))
    box.StaticText(label="FPS Limit", pos=(0, 139))
    

    fpslimit.wEvent_Text do ():
        try:
            var val = fpslimit.getText().parseInt
            if val < -1: fpslimit.setValue(0)
            elif val > 960: fpslimit.setValue(960)
        except ValueError: fpslimit.setValue(0)

    rs.wEvent_Text do ():
        try:
            var val = rs.getText().parseInt
            if val < -1: rs.setValue(50)
            elif val > 101: rs.setValue(100)
        except ValueError: rs.setValue(50)

    save.wEvent_Button do ():
        var 
            game = rs.getText()
            sk = [dm.getValue(), nvr.getValue(), scc.getValue(), fpslimit.getText()]     
        if game.parseInt <= 50: game = "50"; rs.setText(game)
        if sk[0] == dm[dm.len-1]: native = true
        if sk[2] == cpusopts[cpusopts.len-1]: sk[2] = "-1"
        if sk[3].parseInt in 1..29: sk[3] = "30"; fpslimit.setText(sk[3])
        setSKSettings(sk[0], sk[1], sk[2], sk[3], native)
        setGameSettings(game)
        frame.MessageDialog("Settings saved!", "ZetaConfig", wOk or wIconInformation).display()
        
    about.wEvent_Button do ():
        frame.MessageDialog("Created by Aetopia\nVersion: $1\nhttps://github.com/Aetopia/ZetaConfig" % version, "About", wOk or wIconInformation).display()

    frame.center()
    frame.show()
    app.mainLoop()