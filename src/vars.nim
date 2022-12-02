import steam
import os

let
  steampath = getSteamPath() 
  localappdata* = getEnv("LOCALAPPDATA")
  gamedir* = getSteamGameInstallDir("Halo Infinite", steampath)
  dxgiini* = gamedir/"dxgi.ini"
  gameconfig* = localappdata/"HaloInfinite/Settings/SpecControlSettings.json"
  steamclient* = steampath/"steam.exe"
  documents* = getEnv("USERPROFILE")/"Documents"
  temp* = getEnv("TEMP")
  wdmthook* = "\n[Import.WDMTHook]\nArchitecture=x64\nFilename=WDMTHook.dll\nRole=ThirdParty\nWhen=Late"
  wdmt* = gamedir/"WDMT.txt"