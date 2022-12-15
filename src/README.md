# Building
Here, you can find the source code for the following.

|Project|Description|
|-|-|
|**ZetaMod**|A tool to fix performance issues with Halo Infinite.|
|**Zeta**|A project that aims to reintroduce missing features into Halo Infinite.|

Use `build.bat` to build every project on this repository.             
ZetaMod comes with `Zeta.dll`.        

1. Install Nim: https://github.com/dom96/choosenim
    > Run the tool 2~3 times to ensure Nim installs properly.
    > If Nim isn't in your `SYSTEM` path, then log out and log back in.

2. Install the following dependencies:
    ```
    nimble install winim
    ```

## ZetaMod
Run the following command to compile:
```
nim c -d:release -d:strip --opt:size -o:ZetaMod.exe ZetaMod/main.nim
```
> Optional: Compress using UPX.         
    ```
    upx -9 ZetaMod.exe
    ```

## Zeta
```
nim c -d:release -d:strip --app:lib -o:Zeta.dll Zeta/Zeta.nim
```

> **Optional:** Compress using UPX!          
    ```
    upx --best Zeta.dll
    ```