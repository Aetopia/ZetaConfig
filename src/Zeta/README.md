# Zeta
This project gets it name from Zeta Halo, the ring where Halo Infinite takes place.
A library that aims to fix and add missing technical features into Halo Infinite.
## Features
1. Use a specific display mode/display resolution of your choice with a specific windowed program for better performance.
    > Adds a Fullscreen Exclusive feature back into the game.
2. Fix for Halo Infinite's Borderless Fullscreen not scaling correctly for resolutions below `1440x810` for `16:9` monitors.
    > Fixes an issue where Halo Infinite's Borderless Fullscreen doesn't fill `1360x768` correctly.
3. Automatically minimize a borderless window when its not the foreground window for better multitasking.

## How to load Zeta via Special K?
Add the following to your Special K local install configuration file.
```ini
[Import.Zeta]
Architecture=x64
Filename=Zeta.dll
Role=ThirdParty
When=Late
```
> For more reference: https://wiki.special-k.info/en/SpecialK/Tools#custom-plugin


## To to use a specific display mode/resolution?
**Note: Ensure Borderless Fullscreen is enabled!**
1. Browse Halo Infinite's local files.
2. Find `Zeta.txt` and open it.
3. It should look like this:
    ```
    1920
    1080
    ```
    By default, these values should the width and height of your monitor's native resolution.
4. Set a custom display mode/resolution like this:
    ```
    1280
    720
    ```
5. Save the file.