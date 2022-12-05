@echo off
cd %~dp0
nim c -d:release -d:strip --opt:size -o:ZetaConfig.exe ZetaConfig/main.nim
gcc -Wall -Wextra -Ofast -s -mwindows -o "WDMT.exe" "WDMT/main.c" -lshcore
gcc -Wall -Wextra -Ofast -s -shared -o "WDMT.dll" "WDMT/dll.c"
upx --best WDMT.exe WDMT.dll ZetaConfig.exe