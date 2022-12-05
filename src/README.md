# Building
Here, you can find the source code for the following.

|Project|Description|
|-|-|
|**ZetaConfig**|A tool to fix performance issues with Halo Infinite.|
|**Window Display Mode Tool**|A tool to allow windowed programs to use any display mode and go borderless.

Use `build.bat` to build every project on this repository.

ZetaConfig comes with `WDMT.exe` and `WDMT.dll` embedded as base64 encoded strings.
These strings can be found in `ZetaConfig/vars.nim` with variables names `wdmtexe` & `wdmtdll`.
To convert their content into `base64` using the following commands:
- `WDMT.exe`
    ```ps
    [Convert]::ToBase64String((Get-Content "WDMT.exe" -Encoding Byte)) | Set-Clipboard
    ```
- `WDMT.dll`
    ```ps
    [Convert]::ToBase64String((Get-Content "WDMT.dll" -Encoding Byte)) | Set-Clipboard
    ```

## ZetaConfig
1. Install Nim: https://github.com/dom96/choosenim
    > Run the tool 2~3 times to ensure Nim installs properly.
    > If Nim isn't in your `SYSTEM` path, then log out and log back in.

2. Install the following dependencies:
    ```
    nimble install wNim
    ```

3. Run the following command to compile:
    ```
    nim c -d:release -d:strip --opt:size -o:ZetaConfig.exe ZetaConfig/main.nim
    ```
    > Optional: Compress using UPX.         
        ```
        upx -9 ZetaConfig.exe
        ```

## Window Display Mode Tool
1. Install `GCC`.

2. Build:
    - `WDMT.exe`
        ```
        gcc -Wall -Wextra -Ofast -s -mwindows -o "WDMT.exe" "WDMT/main.c" -lshcore
        ```

    - `WDMTHook.dll`

        ```
        gcc -Wall -Wextra -Ofast -s -shared -o "WDMT.dll" "WDMT/dll.c"
        ```

    - **Optional:** Compress using UPX!
        ```
        upx --best WDMT.exe WDMTHook.dll
        ```