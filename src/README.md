# Building
Here, you can find the source code for the following.

|Project|Description|
|-|-|
|**ZetaConfig**|A tool to fix performance issues with Halo Infinite.|
|**Borderless Window Extended**|A tool to allow windowed programs to use any display mode and go borderless.

Use `build.bat` to build every project on this repository.             
ZetaConfig comes with `BWEx.exe` and `BWEx.dll` embedded.           

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
    - `BWEx.exe`
        ```
        gcc -Wall -Wextra -Ofast -s -mwindows -o "BWEx.exe" "Borderless-Window-Extended/main.c" -lshcore
        ```

    - `BWExHook.dll`

        ```
        gcc -Wall -Wextra -Ofast -s -shared -o "BWEx.dll" "Borderless-Window-Extended/dll.c"
        ```

    - **Optional:** Compress using UPX!
        ```
        upx --best BWEx.exe BWExHook.dll
        ```