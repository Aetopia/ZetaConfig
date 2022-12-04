#include <windows.h>
#include <stdio.h>

void GetMonitorName(HWND hwnd, char *file)
{
    MONITORINFOEX mi;
    FILE *f;
    mi.cbSize = sizeof(mi);
    GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), (MONITORINFO *)&mi);
    f = fopen(file, "w");
    fprintf(f, mi.szDevice);
    fclose(f);
}