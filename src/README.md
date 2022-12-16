# Building
Here, you can find the source code for the following.

|Project|Description|
|-|-|
|**ZetaPatcher**|A tool to fix performance issues with Halo Infinite.|
|**Zeta**|A library that aims to fix and add missing technical features into Halo Infinite.|

Use `build.bat` to build every project on this repository.             
ZetaPatcher comes with `Zeta.dll`.        

1. Install Nim: https://github.com/dom96/choosenim
    > Run the tool 2~3 times to ensure Nim installs properly.
    > If Nim isn't in your `SYSTEM` path, then log out and log back in.

2. Install the following dependencies:
    ```
    nimble install winim
    ```

## ZetaPatcher
Run the following command to compile:
```
nim c -d:release -d:strip --opt:size -o:ZetaPatcher.exe ZetaPatcher/main.nim
```
> Optional: Compress using UPX.         
    ```
    upx -9 ZetaPatcher.exe
    ```

## Zeta
```
nim c -d:release -d:strip --app:lib -o:Zeta.dll Zeta/Zeta.nim
```

> **Optional:** Compress using UPX!          
    ```
    upx --best Zeta.dll
    ```