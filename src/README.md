# Building
Here, you can find the source code for the following.

|Project|Description|
|-|-|
|**ZetaConfig**|A tool to fix performance issues with Halo Infinite.|
|**Borderless Window Extended**|A tool to allow windowed programs to use any display mode and go borderless.

Use `build.bat` to build every project on this repository.             
ZetaConfig comes with `BWEx.exe` and `BWEx.dll` embedded.           

1. Install Nim: https://github.com/dom96/choosenim
    > Run the tool 2~3 times to ensure Nim installs properly.
    > If Nim isn't in your `SYSTEM` path, then log out and log back in.

2. Install the following dependencies:
    ```
    nimble install winim
    ```

## ZetaConfig
Run the following command to compile:
```
nim c -d:release -d:strip --opt:size -o:ZetaConfig.exe ZetaConfig/main.nim
```
> Optional: Compress using UPX.         
    ```
    upx -9 ZetaConfig.exe
    ```

## Zeta
```
nim c -d:release -d:strip --app:lib -o:Zeta.dll Zeta/Zeta.nim
```

> **Optional:** Compress using UPX!          
    ```
    upx --best Zeta.dll
    ```