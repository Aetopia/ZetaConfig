@echo off
cd %~dp0

:: Compile Borderless Window Extended.
gcc -Wall -Wextra -Ofast -s -mwindows -o "BWEx.exe" "Borderless-Window-Extended/main.c" -lshcore
gcc -Wall -Wextra -Ofast -s -shared -o "BWEx.dll" "Borderless-Window-Extended/dll.c"
upx --best BWEx.exe BWEx.dll >nul 2>&1 

:: Compile ZetaConfig.
nim c -d:release -d:strip --opt:size -o:ZetaConfig.exe ZetaConfig/main.nim
del /Q BWEx.exe BWEx.dll
upx --best ZetaConfig.exe >nul 2>&1 