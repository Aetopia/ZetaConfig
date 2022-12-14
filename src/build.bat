@echo off
cd %~dp0

nim c -d:release -d:strip --app:lib -o:Zeta.dll Zeta/Zeta.nim
upx --best Zeta.dll >nul 2>&1 

:: Compile ZetaConfig.
nim c -d:release -d:strip --opt:size -o:ZetaMod.exe ZetaMod/main.nim
del /Q Zeta.dll
upx --best ZetaConfig.exe >nul 2>&1 