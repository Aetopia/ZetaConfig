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
  zetaimp* = "\n[Import.Zeta]\nArchitecture=x64\nFilename=Zeta.dll\nRole=ThirdParty\nWhen=Late"
  zetadll* = gamedir/"Zeta.dll"
const zeta* = staticRead"../Zeta.dll"