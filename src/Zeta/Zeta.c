#include <windows.h>
#include <shellscalingapi.h>

// Make this a global structure so it can be easily accessed by functions.
struct WINDOW
{
    HWND hwnd;        // HWND of the hooked process's window & reserved HWND variable.
    DEVMODE dm;       // Display mode to be applied when the hooked process' window is in the foreground
    DWORD pid;        // PID of the hooked process & reserved variables.
    MONITORINFOEX mi; // Info of the monitor, the hooked process' window is present on.
    BOOL cds;         // CDS toggles between setting a resolution and resetting it.
    int cx, cy;       // Hooked process' window client size.
};
struct WINDOW wnd = {.mi.cbSize = sizeof(wnd.mi),
                     .dm.dmSize = sizeof(wnd.dm),
                     .dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT,
                     .cds = FALSE};

void SetDM(DEVMODE *dm)
{
    ChangeDisplaySettingsEx(wnd.mi.szDevice, dm, NULL, CDS_FULLSCREEN, NULL);
    if (dm == 0)
        ChangeDisplaySettingsEx(wnd.mi.szDevice, 0, NULL, 0, NULL);
}

BOOL IsProcWndForeground(HWND hwnd)
{
    DWORD pid;
    GetWindowThreadProcessId(hwnd, &pid);
    if (wnd.pid == pid)
    {
        if (wnd.hwnd != hwnd)
        {
            wnd.hwnd = hwnd;
        };
        return TRUE;
    };
    return FALSE;
}

DWORD SetWndPosThread()
{
    do
    {
        SetWindowPos(wnd.hwnd, 0,
                     wnd.mi.rcMonitor.left, wnd.mi.rcMonitor.top,
                     wnd.cx, wnd.cy,
                     SWP_NOACTIVATE |
                         SWP_NOSENDCHANGING |
                         SWP_NOOWNERZORDER |
                         SWP_NOZORDER);
        Sleep(1);
    } while (TRUE);
    return TRUE;
}

void WinEventProc(
    __attribute__((unused)) HWINEVENTHOOK hWinEventHook,
    DWORD event,
    HWND hwnd,
    __attribute__((unused)) LONG idObject,
    __attribute__((unused)) LONG idChild,
    __attribute__((unused)) DWORD idEventThread,
    __attribute__((unused)) DWORD dwmsEventTime)
{
    if (event == EVENT_SYSTEM_FOREGROUND)
    {
        switch (IsProcWndForeground(hwnd))
        {
        case TRUE:
            if (wnd.cds)
            {
                if (IsIconic(wnd.hwnd))
                    ShowWindow(wnd.hwnd, SW_RESTORE);
                if (!!wnd.dm.dmFields)
                    SetDM(&wnd.dm);
                wnd.cds = FALSE;
            };
            return;
        case FALSE:
            if (!wnd.cds)
            {
                if (!IsIconic(wnd.hwnd))
                    ShowWindow(wnd.hwnd, SW_MINIMIZE);
                if (!!wnd.dm.dmFields)
                    SetDM(0);
                wnd.cds = TRUE;
            }
        }
    };
}

DWORD HaloInfWndDM()
{
    DEVMODE dm;
    HMONITOR hmon;
    UINT dpi;
    MSG msg;
    float scale;

    /* References:
    https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
    https://github.com/Codeusa/Borderless-Gaming/blob/master/BorderlessGaming.Logic/Windows/Manipulation.cs
    https://learn.microsoft.com/en-us/windows/win32/direct2d/how-to--size-a-window-properly-for-high-dpi-displays
    */

    // Get Halo Infinite's HWND and make the window borderless.
    while (!IsProcWndForeground(GetForegroundWindow()))
        Sleep(0);
    SetWindowLongPtr(wnd.hwnd, GWL_STYLE,
                     GetWindowLongPtr(wnd.hwnd, GWL_STYLE) & ~(WS_OVERLAPPEDWINDOW));
    SetWindowLongPtr(wnd.hwnd, GWL_EXSTYLE,
                     GetWindowLongPtr(wnd.hwnd, GWL_EXSTYLE) & ~(WS_EX_DLGMODALFRAME |
                                                                 WS_EX_COMPOSITED |
                                                                 WS_EX_OVERLAPPEDWINDOW |
                                                                 WS_EX_LAYERED |
                                                                 WS_EX_STATICEDGE |
                                                                 WS_EX_TOOLWINDOW |
                                                                 WS_EX_APPWINDOW |
                                                                 WS_EX_TOPMOST));

    // Restore the window if its maximized.
    if (IsZoomed(wnd.hwnd))
        ShowWindow(wnd.hwnd, SW_RESTORE);

    /*
    1. Get the monitor, the window is present on.
    2. Get the DPI set for the monitor after the display resolution change.
    Prevent SetDM(DEVMODE *dm) from being called if window size is the same as the current display resolution.
    3. Find the scaling factor for sizing the window.
    Scaling Factor: `[DPI of the monitor after the resolution change.) / 96]`.
    4. Set a event hook for EVENT_SYSTEM_FOREGROUND.
    */
    hmon = MonitorFromWindow(wnd.hwnd, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(hmon, (MONITORINFO *)&wnd.mi);
    EnumDisplaySettings(wnd.mi.szDevice, ENUM_CURRENT_SETTINGS, &dm);
    if (dm.dmPelsWidth == wnd.dm.dmPelsWidth && dm.dmPelsHeight == wnd.dm.dmPelsHeight)
        wnd.dm.dmFields = 0;
    else
        SetDM(&wnd.dm);
    GetDpiForMonitor(hmon, 0, &dpi, &dpi);
    scale = dpi / 96;
    wnd.cx = wnd.dm.dmPelsWidth * scale;
    wnd.cy = wnd.dm.dmPelsHeight * scale;

    SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, 0, WinEventProc, 0, 0, WINEVENT_OUTOFCONTEXT);
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    };
    return 0;
}

void Zeta(int width, int height)
{
    wnd.pid = GetCurrentProcessId();
    wnd.dm.dmPelsWidth = width;
    wnd.dm.dmPelsHeight = height;

    // Check if specified resolution is valid or not.
    if (ChangeDisplaySettings(&wnd.dm, CDS_TEST) != DISP_CHANGE_SUCCESSFUL ||
        (wnd.dm.dmPelsWidth || wnd.dm.dmPelsHeight) == 0)
    {
        return 0;
    }

    // Create threads.
    CreateThread(0, 0, SetWndPosThread, NULL, 0, 0);
    CreateThread(0, 0, HaloInfWndDM, NULL, 0, 0);
}