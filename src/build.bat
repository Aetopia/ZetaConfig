@echo off
cd %~dp0

gcc -Wall -Wextra -Ofast -shared -s Zeta\Zeta.c -lshcore -o Zeta.dll
upx --best Zeta.dll >nul 2>&1 

:: Compile ZetaConfig.
nim c -d:release -d:strip --opt:size -o:ZetaMod.exe ZetaMod/main.nim
del /Q Zeta.dll
upx --best ZetaConfig.exe >nul 2>&1 