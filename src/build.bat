@echo off
cd %~dp0

gcc -Wall -Wextra -Ofast -shared -s Zeta\Zeta.c -lshcore -o Zeta.dll
upx --best Zeta.dll >nul 2>&1 

:: Compile ZetaPatcher.
nim c -d:release -d:strip --opt:size -o:ZetaPatcher.exe ZetaPatcher/main.nim
del /Q Zeta.dll
upx --best ZetaPatcher.exe >nul 2>&1 