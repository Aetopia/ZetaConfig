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
  wdmtsk* = "\n[Import.WDMT]\nArchitecture=x64\nFilename=WDMT.dll\nRole=ThirdParty\nWhen=Early"
  wdmttxt* = gamedir/"WDMT.txt"

# This embeds Window Display Mode Tool when compiling ZetaConfig.
const
  wdmtexe* = staticRead("../WDMT.exe")
  wdmtdll* = staticRead("../WDMT.dll")