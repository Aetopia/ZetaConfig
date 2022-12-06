@echo off
cd %~dp0

:: Compile Window Display Mode Tool.
gcc -Wall -Wextra -Ofast -s -mwindows -o "WDMT.exe" "WDMT/main.c" -lshcore
gcc -Wall -Wextra -Ofast -s -shared -o "WDMT.dll" "WDMT/dll.c"
upx --best WDMT.exe WDMT.dll >nul 2>&1 

:: Compile ZetaConfig.
nim c -d:release -d:strip --opt:size -o:ZetaConfig.exe ZetaConfig/main.nim
del /Q WDMT.exe WDMT.dll 
upx --best ZetaConfig.exe >nul 2>&1 