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
  BWExsk* = "\n[Import.BWEx]\nArchitecture=x64\nFilename=BWEx.dll\nRole=ThirdParty\nWhen=Early"
  BWExtxt* = gamedir/"BWEx.txt"

# This embeds Borderless Window Extended when compiling ZetaConfig.
const
  BWExexe* = staticRead"../BWEx.exe"
  BWExdll* = staticRead"../BWEx.dll"