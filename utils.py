from tempfile import gettempdir
import os
from pathlib import Path
from subprocess import run
os.system('')

class altbuffer():
    def create():
        print('\x1b[?1049h', end='')
    def destroy():
        print('\x1b[?1049l', end='')

class game:
    uwp = 'uwp', os.path.expandvars(
        "%LOCALAPPDATA%\Packages\Microsoft.254428597CFE2_8wekyb3d8bbwe\LocalCache\Local\HaloInfinite\Settings\SpecControlSettings.json")
    steam = 'steam', os.path.expandvars(
        "%LOCALAPPDATA%\HaloInfinite\Settings\SpecControlSettings.json")

    if os.path.exists(uwp[1]):
        type, config = uwp
    elif os.path.exists(steam[1]):
        type, config = steam
    elif os.path.exists(steam[1]) and os.path.exists(uwp[1]):
        raise Exception("Both UWP and Steam versions are installed.")
    else:
        raise Exception("Halo Infinite is not installed.")

    cache, exe = f'{gettempdir()}\\haloinf.txt', ''
    if os.path.exists(cache):
        with open(cache, 'r') as f:
            exe = f.read()
    if not os.path.exists(exe) and not exe:
        drives = [f"{chr(i)}:\\" for i in range(65, 91)
                  if os.path.exists(f"{chr(i)}:\\")]
        for drive in drives:
            try:
                for file in Path(drive).rglob("*HaloInfinite.exe"):
                    with open(f'{gettempdir()}\\haloinf.txt', 'w') as f:
                        f.write(str(file))
                        exe = file
                        break
            except OSError:
                pass
            if exe:
                break
    installdir = os.path.dirname(exe)
