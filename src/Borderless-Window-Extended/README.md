# Borderless Window Extended
A tool to extend the feature set of borderless windowed mode in programs.

## Features
1. Use a specific display mode/display resolution of your choice with a specific windowed program for better performance.
2. Override a program 's borderless window implementation with a statically sized borderless window.
3. Automatically minimize a borderless window when its not the foreground window for better multitasking.

## Usage

### Notes
1. **Ensure your program is set in windowed mode.**
    **The window size is should be the same as the specified display resolution passed to Borderless Window Extended.**
2. **Borderless Window Extended might not work properly with all programs.**
    **Feel free to make a issue on this repository to improve compatibility.**
3. **Borderless Window Extended might not play well with multi monitor setups.**

Pass a process' PID or process name and the desired display resolution to be used with that process.
```
BWEx.exe <PID/Process> <Width> <Height>
```
|Argument|Operation|
|-|-|
|`<PID>`|Specify a PID or Process name to hook onto.|
|`<Width> <Height>`| Resolution to apply.|

### Examples:

- Hook onto a process via its PID.
    ```
    BWEx.exe 1234 1280 720
    ```
- Hook onto a process via its Process Name.
    ```
    BWEx.exe cmd.exe 1280 720
    ```

## Borderless Window Extended Library
**Intended to be used with [Special K](https://wiki.special-k.info).**            
This library allows for a game to start and use `BWEx.exe` everytime it launches.     
This additionally acts an override for Special K's borderless windowed mode implementation.

1. Simply place `BWEx.dll` and `BWEx.exe` in a Special K local install. 
2. Add the following to your Special K configuration file:
    ```ini
    [Import.BWEx]
    Architecture=x64
    Filename=BWEx.dll
    Role=ThirdParty
    When=Early
    ```
3. Create a new file with the name of `BWEx.txt` in the Special K local install directory.                               
    Add the following contents:

    ```txt
    0 0
    ```
    > Where `0 0` is the width and height of the desired display resolution.    

    Example:
    ```txt
    1280 720
    ```
