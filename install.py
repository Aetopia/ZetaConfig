from configparser import ConfigParser
from urllib.request import urlretrieve, urlopen
from tempfile import gettempdir
from subprocess import Popen, run
from utils import game
from time import sleep
from shutil import copyfile
from json import load
import os
from utils import game
from shutil import rmtree


def specialk(check=True):
    path, temp, delay = game.installdir, gettempdir(), 5

    if os.path.exists(f'{path}\\dxgi.dll') and os.path.exists(f'{path}\\dxgi.ini') and check:
        return

    print('Installing Special K...')
    with urlopen('https://api.github.com/repos/SpecialKO/SpecialK/releases/latest') as response:
        url = load(response)["assets"][0]['browser_download_url']
    for x, y in ((url, sk := f'{temp}\\SpecialK.7z'), ("https://www.7-zip.org/a/7zr.exe", _7zr := f'{temp}\\7zr.exe')):
        urlretrieve(x, y)

    run(f'{_7zr} x {sk} -o"{temp}" -y', capture_output=True)
    copyfile(f'{temp}\\SpecialK64.dll', f'{path}\\dxgi.dll')

    for exe in ("ResEnforce.exe", "HaloInfinite.exe"):
        run(f"taskkill /f /im {exe}", capture_output=True)

    while True:
        try:
            Popen(f'{path}\\HaloInfinite.exe')
            sleep(delay)
            while True:
                sleep(0.001)
                if run('tasklist /m /fi "IMAGENAME eq HaloInfinite.exe" /fi "STATUS eq RUNNING"', capture_output=True).returncode == 0:
                    run(f"taskkill /f /im HaloInfinite.exe", capture_output=True)
                    break
            if os.path.exists(sk_ini := f"{path}/dxgi.ini"):
                with open(sk_ini, 'r') as f:
                    if f.read():
                        print('Special K Config File Generated!')
                        raise StopIteration
            else:
                print(
                    'Configuration file generation failed, retrying...')
                delay = 10
        except StopIteration:
            break

    osd = ConfigParser()
    osd.optionxform = str
    osd.read(osd_ini := os.path.expandvars(
        r'%USERPROFILE%\Documents\My Mods\SpecialK\Global\osd.ini'), encoding='utf-8-sig')
    osd['SpecialK.VersionBanner']["Duration"] = "0.0"

    with open(osd_ini, 'w+', encoding='utf-8-sig') as f:
        osd.write(f, space_around_delimiters=False)

    print('Special K Installed!')
    sleep(1)


def resenforce(check=True):
    path = os.path.expandvars(r'%USERPROFILE%\Documents\My Mods\ResEnforce')
    if os.path.exists(f'{path}\\ResEnforce.exe') and check:
        return
    if not os.path.exists(path):
        os.mkdir(path)

    print('Installing ResEnforce...')
    with urlopen('https://api.github.com/repos/Aetopia/ResEnforce/releases/latest') as response:
        url = load(response)["assets"][0]['browser_download_url']

    urlretrieve(url, f'{path}\\ResEnforce.exe')

    os.symlink(f'{path}\\ResEnforce.exe', os.path.expandvars(
        r'%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ResEnforce.exe'))
    print('ResEnforce Installed!')
    sleep(1)


def uninstall():
    path = os.path.expandvars(r'%USERPROFILE%\Documents\My Mods')
    if os.path.exists(path):
        rmtree(path)
        print('Uninstalled!')
        sleep(1)

    for i in ('.dll', '.ini'):
        if os.path.exists(f := f'{game.installdir}\\dxgi{i}'):
            os.remove(f)

    if os.path.exists(f := os.path.expandvars(r'%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ResEnforce.exe')):
        os.remove(f)
