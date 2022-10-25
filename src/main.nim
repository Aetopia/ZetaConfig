import wNim/[wApp, wFrame, wPanel, wStaticBox, wStaticText, wSpinCtrl, wComboBox, wButton, wMessageDialog]
import strutils, sequtils
import cpuinfo
import mods, procs

if isMainModule:
    installMods()
    var 
        # GUI 
        app = App(wPerMonitorDpiAware)
        frame = Frame(title="ZetaConfig", style=wSystemMenu, size=(400, 300))
        box = frame.Panel().StaticBox(label="Settings", pos=(7, 0), size=(380, 265))

        # Data
        dms = getDisplayModes()
        cpusopts: seq[string]
        reflexopts = ["Off", "On", "Boost", "On + Boost"]
    for cpu in toSeq(0..countProcessors()):
        if cpu mod 2 == 0 and cpu >= 4: cpusopts.add(intToStr(cpu))
    
    # Settings
    var 
        (res, cpus, reflex, fps) = getSKSettings()
        resscale = getGameSettings()
    if resscale.parseInt notin 50..100: resscale = "100" 
    if res notin dms: res = dms[dms.len-1]
    if cpus notin cpusopts: cpus = cpusopts[cpusopts.len-1]
    if fps.parseInt notin 0..960: fps = "0"

    box.StaticText(label="Resolution Scale", pos=(0, 3))
    var rs = box.SpinCtrl(pos=(100, 0), 
                    style=wSpCenter or wSpArrowKeys)
    rs.setValue(resscale)
    rs.setRange(50..100)
    rs.wEvent_Text do ():
        try:
            var val = rs.getText().parseInt
            if val < -1: rs.setValue(50)
            elif val > 101: rs.setValue(100)
        except ValueError: rs.setValue(50)

    box.StaticText(label="Display Mode", pos=(0, 37))
    var dm = box.ComboBox(size=(120, 23), pos=(100, 34), 
                        style=wCbDropDown or wCbReadOnly or wCbNeededScroll, 
                        choices=dms, value=res)

    box.StaticText(label="Spoof CPU Cores", pos=(0, 71))
    var scc = box.ComboBox(size=(120, 23), pos=(100, 68), 
                                    style=wCbDropDown or wCbReadOnly or wCbNeededScroll, 
                                    choices=cpusopts, value=cpus)

    box.StaticText(label="NVIDIA Reflex", pos=(0, 106))
    var nvr = box.ComboBox(size=(120, 23), pos=(100, 102), 
                                style=wCbDropDown or wCbReadOnly or wCbNeededScroll, 
                                choices=reflexopts, value=reflex)
    
    box.StaticText(label="FPS Limit", pos=(0, 139))
    var fpslimit = box.SpinCtrl(pos=(100, 137), 
                                style=wSpCenter or wSpArrowKeys)
    fpslimit.setValue(fps)
    fpslimit.setRange(0..960)
    fpslimit.wEvent_Text do ():
        try:
            var val = fpslimit.getText().parseInt
            if val < -1: fpslimit.setValue(0)
            elif val > 960: fpslimit.setValue(960)
        except ValueError: fpslimit.setValue(0)
    
    var save = box.Button(label="Save", pos=(269, 208))
    save.wEvent_Button do ():
        var 
            game = rs.getText()
            sk = [dm.getValue(), nvr.getValue(), scc.getValue(), fpslimit.getText()]     
        if game.parseInt <= 50: game = "50"; rs.setText(game)
        if sk[0] == dms[dms.len-1]: sk[0] = "0x0" 
        if sk[2] == cpusopts[cpusopts.len-1]: sk[2] = "-1"
        if sk[3].parseInt in 1..29: sk[3] = "30"; fpslimit.setText(sk[3])
        setSKSettings(sk[0], sk[1], sk[2], sk[3])
        setGameSettings(game)
        frame.MessageDialog("Settings saved!", "ZetaConfig", wOk or wIconInformation).display()
        
    frame.center()
    frame.show()
    app.mainLoop()