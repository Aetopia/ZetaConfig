## Window Display Mode Tool
Pass a process' PID or process name and the desired display mode to be used with that process.

```
WDMT.exe <PID/Process> <Width> <Height>
```
|Argument|Operation|
|-|-|
|`<PID>`|Specify a PID or Process name to hook onto.|
|`<Width> <Height>`| Resolution to apply.|

### Examples:

- Hook onto a process via its PID.
    ```
    WDMT.exe 1234 1280 720
    ```
- Hook onto a process via its Process Name.
    ```
    WDMT.exe cmd.exe 1280 720
    ```

## Window Display Mode Tool Library
**Intended to be used with [Special K](https://wiki.special-k.info).**            
This library allows for a game to start and use `WDMT.exe` everytime it launches.

1. Simply place `WDMT.dll` and `WDMT.exe` in a Special K local install. 
2. Add the following to your Special K configuration file:
    ```ini
    [Import.WDMT]
    Architecture=x64
    Filename=WDMT.dll
    Role=ThirdParty
    When=Early
    ```