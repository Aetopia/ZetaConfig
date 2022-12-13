import wNim/[wApp, wFrame, wPanel, wStaticBox, wStaticText, wSpinCtrl, wComboBox, wButton, wMessageDialog]
import winim/[lean, shell]
import strutils, sequtils
import os, osproc
import mods, settings, hardware, vars

if isMainModule:
    SetConsoleTitle("ZetaConfig Console")
    if fileExists(localappdata/"Packages\\Microsoft.254428597CFE2_8wekyb3d8bbwe\\LocalCache\\Local\\HaloInfinite\\Settings\\SpecControlSettings.json"):
        MessageBox(0, "Halo Infinite has been installed via the Microsoft Store.\nZetaConfig only supports the Steam version of the game.", "ZetaConfig", MB_ICONERROR)
        quit(1)
    getGameDisplay()
    installMods()

    # Settings
    var
        dms = getDisplayModes()
        resscale = getGameSettings()
        cpusopts: seq[string]
        (res, cpus, reflex, fps) = getSettings()

    for cpu in toSeq(0..countProcessors()):
        if cpu mod 2 == 0 and cpu >= 4: cpusopts.add(intToStr(cpu))
    if resscale.parseInt notin 50..100: resscale = "100" 
    if res notin dms: res = dms[dms.len-1]
    if cpus notin cpusopts: cpus = cpusopts[cpusopts.len-1]
    if fps.parseInt notin 0..960: fps = "0"

    # GUI 
    let 
        app = App(wPerMonitorDpiAware)
        frame = Frame(title="ZetaConfig", style=wSystemMenu, size=(400, 300))
        box = frame.Panel().StaticBox(label="Settings", pos=(7, 0), size=(380, 265))
        rs = box.SpinCtrl(pos=(100, 0), style=wSpCenter or wSpArrowKeys)
        dm = box.ComboBox(size=(120, 23), pos=(100, 34), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=dms, value=res)
        scc = box.ComboBox(size=(120, 23), pos=(100, 68), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=cpusopts, value=cpus)
        nvr = box.ComboBox(size=(120, 23), pos=(100, 102), style=wCbDropDown or wCbReadOnly or wCbNeededScroll, choices=["Off", "On", "Boost", "On + Boost"], value=reflex)
        fpslimit = box.SpinCtrl(pos=(100, 137), style=wSpCenter or wSpArrowKeys)
        save = box.Button(label="Save", pos=(269, 208))
        about = box.Button(label="?", pos=(0, 208), size=(26, 26))
        repo = box.Button(label="🌎", pos=(34, 208), size=(26, 26))
        redetect = box.Button(label="🖥️", pos=(68, 208), size=(26, 26))
        uninstall = box.Button(label="🗑️", pos=(102, 208), size=(26, 26))
        
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
            settings = [dm.getValue().replace("x", " "), nvr.getValue(), scc.getValue(), fpslimit.getText()]  
            resscale = rs.getText() 
        if resscale.parseInt <= 50: resscale = "50"; rs.setText(resscale)
        if settings[2] == cpusopts[cpusopts.len-1]: settings[2] = "-1"
        if settings[3].parseInt in 1..29: settings[3] = "30"; fpslimit.setText(settings[3])
        setGameSettings(resscale)
        setSettings(settings[0], settings[1], settings[2], settings[3])
        frame.MessageDialog("Settings saved!", "Save", wOk or wIconInformation).display()
        
    about.wEvent_Button do ():
        frame.MessageDialog("Created by Aetopia\nhttps://github.com/Aetopia/ZetaConfig", "About", wOk or wIconInformation).display()

    repo.wEvent_Button do ():
        ShellExecute(0, "open", "https://github.com/Aetopia/ZetaConfig", nil, nil, 0)
        
    redetect.wEvent_Button do ():
        if frame.MessageDialog("Redetect which monitor, Halo Infinite launches on?", "Redetect", wOkCancel or wIconExclamation).display() == wIdOk:
            removeFile(gamedir/"ZetaConfig.txt")
            ShellExecute(0, "open", getAppFilename(), nil, nil, 5)
            quit(0)

    uninstall.wEvent_Button do ():
        if frame.MessageDialog("Uninstall Special K and Borderless Window Extended?", "Uninstall", wOkCancel or wIconExclamation).display() == wIdOk:
            uninstallMods()
            frame.hide()
            MessageDialog(nil, "Uninstalled Special K and Borderless Window Extended.", "Uninstall", wOk or wIconInformation).display()
            quit(0)
            
    frame.center()
    frame.show()
    app.mainLoop()