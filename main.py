import json
import sys
from configparser import ConfigParser
from getpass import getpass
from traceback import print_exc
from install import resenforce, specialk, uninstall
from settings import settings
from utils import *

# Poorly written for something functional, might improve later.


class menu():
    def __init__(self):
        self.halo = game()

        with open(self.halo.config, 'r') as f:
            spec = json.load(f)
        dxgi = ConfigParser(interpolation=None, strict=False)
        dxgi.optionxform = str
        dxgi.read(f'{self.halo.installdir}/dxgi.ini', encoding='utf-8-sig')

        spec['spec_control_window_mode']['value'] = spec['spec_control_vsync']['value'] = 0
        for i in ('spec_control_minimum_framerate', 'spec_control_target_framerate'):
            spec[i]['value'] = 960

        for i in ('Borderless', 'Center', 'RenderInBackground'):
            dxgi['Window.System'][i] = 'true'
        for i in ('XOffset', 'YOffset'):
            dxgi['Window.System'][i] = '0.0001%'

        with open(self.halo.config, 'w') as f:
            json.dump(spec, f, indent=4)
        with open(f'{self.halo.installdir}/dxgi.ini', 'w') as f:
            dxgi.write(f, space_around_delimiters=False)

    def run(self):
        dxgi = ConfigParser(interpolation=None)
        dxgi.optionxform = str
        dxgi.read(
            dxgi_ini := f'{self.self.halo.installdir}/dxgi.ini', encoding='utf-8-sig')

        re = ConfigParser()
        re.optionxform = str
        re.read(re_ini := os.path.expandvars(
            r'%USERPROFILE%\Documents\My Mods\ResEnforce\Options.ini'))
        if "HaloInfinite.exe" not in re['Profiles']:
            re['Profiles']['HaloInfinite.exe'] = "0x0"

        sync = True
        with open(self.halo.config, 'r') as f:
            spec = json.load(f)
            for i in settings:
                if spec[i] != settings[i]:
                    sync = False

        while True:
            altbuffer.create()
            print(f'''ZetaConfig (Poorly written but functional!)
            
1. Display Resolution > {re['Profiles']['HaloInfinite.exe']}
2. Framerate Limit > {dxgi['Render.FrameRate']['TargetFPS'].strip('-')}
3. Performance Mode > {sync}
4. Spoof CPU Core Count > {True if dxgi['FrameRate.Control']['OverrideCPUCoreCount'] == '4' else False}
5. Exit''')
            match input('> '):
                case '1':
                    dm = re['Profiles']['HaloInfinite.exe'] = dxgi['Window.System']['OverrideRes'] = input(
                        'Enter Resolution (e.g. 1280x720): ').replace(' ', '').strip().lower()
                    with open(self.halo.config, 'r') as f:
                        spec = json.load(f)
                        x, y = dm.strip().replace(' ', '').split('x', 1)
                        x, y = x.strip(), y.strip()
                        spec[f"spec_control_windowed_display_resolution_x"]['value'] = int(
                            x)
                        spec[f"spec_control_windowed_display_resolution_y"]['value'] = int(
                            y)
                        if x == '1280' and y == '720':
                            spec['spec_control_resolution_scale']['value'] = 100
                        with open(self.halo.config, 'w') as f:
                            json.dump(spec, f, indent=4)

                    with open(dxgi_ini, 'w') as f:
                        dxgi.write(f, space_around_delimiters=False)
                    with open(re_ini, 'w') as f:
                        re.write(f)
                case '2':
                    dxgi['Render.FrameRate']['TargetFPS'] = f"{float(input('Framerate Limit > '))}"
                    with open(dxgi_ini, 'w') as f:
                        dxgi.write(f, space_around_delimiters=False)
                case '3':
                    with open(self.halo.config, 'r') as f:
                        spec = json.load(f)
                        for i in settings:
                            spec[i] = settings[i]
                        sync = True
                        with open(self.halo.config, 'w') as f:
                            json.dump(spec, f, indent=4)
                case '4':
                    val = dxgi['FrameRate.Control']['OverrideCPUCoreCount']
                    if val == '4':
                        dxgi['FrameRate.Control']['OverrideCPUCoreCount'] = '-1'
                    else:
                        dxgi['FrameRate.Control']['OverrideCPUCoreCount'] = '4'
                    with open(dxgi_ini, 'w') as f:
                        dxgi.write(f, space_around_delimiters=False)
                case '5':
                    print('Uninstall everything installed by ZetaConfig?')
                    if input('(Y)es/(N)o > ').lower() == 'y':
                        uninstall()
                case '6':
                    altbuffer.destroy()
                    return
                case _:
                    pass


def main():
    resenforce()
    specialk()
    menu().run()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        altbuffer.destroy()
        sys.exit(1)
    except Exception as e:
        print_exc()
        getpass('Press enter to exit...')
        altbuffer.destroy()
