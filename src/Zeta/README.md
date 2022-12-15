# Zeta
This project gets it name from Zeta Halo, the ring where Halo Infinite takes place.

## Features
**Note: Zeta's aims to reintroduce missing features into Halo Infinite.**
1. Use a specific display mode/display resolution of your choice with a specific windowed program for better performance.
2. Overrides a program's borderless windowed mode implementation with a statically sized borderless window.
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
1. Open `"%LOCALAPPDATA%\HaloInfinite\Settings\SpecControlSettings.json"`
2. Find the following entries:
    ```json
    "spec_control_windowed_display_resolution_x": {
        "version": 0,
        "value": 1920
    },
    "spec_control_windowed_display_resolution_y": {
        "version": 0,
        "value": 1080
    }
    ```
3. Change these values to your desired resolution's height and weight:           
    Example: 
    > `1280` x `720`

    ```json
    "spec_control_windowed_display_resolution_x": {
        "version": 0,
        "value": 1280
    },
    "spec_control_windowed_display_resolution_y": {
        "version": 0,
        "value": 720
    }
    ```
4. Save the file.