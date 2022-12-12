// Borderless Window Extended
#include <windows.h>
#include <shellscalingapi.h>

// Prototypes

// Set the display mode.
void SetDM(DEVMODE *dm);

// Show a message box regarding about an invalid PID.
void PIDErrorMsgBox();

// Set the window style by getting the current window style and adding additional styles to the current one.
void SetWndStyle(int nIndex, LONG_PTR Style);

// Structure that contains information on the hooked process' window.
struct WINDOW;

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground();

// Check for a specific foreground window via its PID and get a handle to the process
void HookForegroundWndProc();

// Wrapper around SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags).
DWORD SetWndPosThread();

// Check if the hooked process is alive or not.
DWORD IsProcAliveThread();

// Hooked process' window's display mode apply and reset loop.
void ForegroundWndDMProc();

// Make this global structure so it can be easily accessed by functions.
struct WINDOW
{
    HWND wnd, hwnd;         // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;           // HANDLE to the hooked process.
    DEVMODE dm;             // Display mode to be applied when the hooked process' window is in the foreground
    DWORD process, ec, pid; // PID of the hooked process & reserved variables.
    MONITORINFOEX mi;       // Info of the monitor, the hooked process' window is present on.
    int cx, cy;             // Hooked process' window client size.
};
struct WINDOW wnd;

void SetDM(DEVMODE *dm)
{
    ChangeDisplaySettingsEx(wnd.mi.szDevice, dm, NULL, CDS_FULLSCREEN, NULL);
}
void PIDErrorMsgBox() { MessageBox(0, "Invaild PID!", "Borderless Windowed Extended", MB_ICONEXCLAMATION); }
void SetWndStyle(int nIndex, LONG_PTR Style) { SetWindowLongPtr(wnd.wnd, nIndex, GetWindowLongPtr(wnd.wnd, nIndex) & ~(Style)); }

BOOL IsProcWndForeground()
{
    Sleep(1);
    wnd.hwnd = GetForegroundWindow();
    GetWindowThreadProcessId(wnd.hwnd, &wnd.pid);
    if (wnd.process == wnd.pid && wnd.hwnd != NULL)
    {
        if (wnd.wnd != wnd.hwnd)
        {
            wnd.wnd = wnd.hwnd;
        };
        return FALSE;
    };
    return TRUE;
}

void HookForegroundWndProc()
{
    wnd.hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, wnd.process);
    if (!wnd.hproc)
    {
        CloseHandle(wnd.hproc);
        PIDErrorMsgBox();
        ExitProcess(1);
    }
    while (!!IsProcWndForeground())
        ;
}

DWORD SetWndPosThread()
{
    while (TRUE)
    {
        Sleep(1);
        SetWindowPos(wnd.wnd, 0,
                     wnd.mi.rcMonitor.left, wnd.mi.rcMonitor.top,
                     wnd.cx, wnd.cy,
                     SWP_NOACTIVATE |
                         SWP_NOSENDCHANGING |
                         SWP_NOOWNERZORDER |
                         SWP_NOZORDER);
    };
    return TRUE;
}

DWORD IsProcAliveThread()
{
    DEVMODE dm;
    dm.dmSize = sizeof(dm);
    while (TRUE)
    {
        Sleep(1);
        if (GetExitCodeProcess(wnd.hproc, &wnd.ec) &&
            ((wnd.ec != STILL_ACTIVE && !IsWindow(wnd.wnd)) ||
             IsHungAppWindow(wnd.wnd)))
        {
            CloseHandle(wnd.hproc);
            do
            {
                EnumDisplaySettings(wnd.mi.szDevice, ENUM_CURRENT_SETTINGS, &dm);
            } while (dm.dmPelsWidth == wnd.dm.dmPelsWidth &&
                     dm.dmPelsHeight == wnd.dm.dmPelsHeight);
            ChangeDisplaySettingsEx(wnd.mi.szDevice, 0, NULL, 0, NULL);
            ExitProcess(0);
        };
    };
    return TRUE;
}

void ForegroundWndDMProc()
{
    while (TRUE)
    {
        // Switch back to native display resolution.
        while (!IsProcWndForeground())
            ;
        if (!IsIconic(wnd.wnd))
            ShowWindow(wnd.wnd, SW_MINIMIZE);
        SetDM(0);

        // Switch to the desired display resolution.
        while (IsProcWndForeground())
            ;
        if (IsIconic(wnd.wnd))
            ShowWindow(wnd.wnd, SW_RESTORE);
        SetDM(&wnd.dm);
    };
}

int main(int argc, char *argv[])
{
    CreateThread(0, 0, IsProcAliveThread, NULL, 0, 0);
    CreateThread(0, 0, SetWndPosThread, NULL, 0, 0);
    HMONITOR hmon;
    UINT dpi;
    float scale;
    wnd.mi.cbSize = sizeof(wnd.mi);
    wnd.dm.dmSize = sizeof(wnd.dm);

    if (argc != 4)
    {
        MessageBox(0,
                   "BWEx.exe <PID> <Width> <Height>",
                   "Borderless Windowed Extended",
                   MB_ICONINFORMATION);
        return 0;
    };

    // Setup the DEVMODE structure.
    wnd.dm.dmPelsWidth = atoi(argv[2]);
    wnd.dm.dmPelsHeight = atoi(argv[3]);
    wnd.dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT;

    // Check if specified resolution is valid or not.
    if (ChangeDisplaySettings(&wnd.dm, CDS_TEST) != DISP_CHANGE_SUCCESSFUL ||
        (wnd.dm.dmPelsWidth || wnd.dm.dmPelsHeight) == 0)
    {
        MessageBox(0,
                   "Invaild Resolution!",
                   "Borderless Windowed Extended",
                   MB_ICONEXCLAMATION);
        return 1;
    }

    // Check if the <PID> argument contains only integers or not.
    if (strspn(argv[1], "0123456789") == strlen(argv[1]))
    {
        wnd.process = atoi(argv[1]);
        HookForegroundWndProc(&wnd);
    }
    else
    {
        PIDErrorMsgBox();
        return 1;
    };

    /* References:
    https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
    https://github.com/Codeusa/Borderless-Gaming/blob/master/BorderlessGaming.Logic/Windows/Manipulation.cs
    https://learn.microsoft.com/en-us/windows/win32/direct2d/how-to--size-a-window-properly-for-high-dpi-displays
    */

    // Restore the window if its maximized.
    if (IsZoomed(wnd.wnd))
        ShowWindow(wnd.wnd, SW_RESTORE);

    // Set the window style to borderless.
    SetWndStyle(GWL_STYLE, WS_OVERLAPPEDWINDOW);
    SetWndStyle(GWL_EXSTYLE, WS_EX_DLGMODALFRAME | WS_EX_COMPOSITED | WS_EX_OVERLAPPEDWINDOW | WS_EX_LAYERED | WS_EX_STATICEDGE | WS_EX_TOOLWINDOW | WS_EX_APPWINDOW | WS_EX_TOPMOST);

    /*
    1. Get the monitor, the window is present on.
    2. Get the DPI set for the monitor after the display resolution change.
    3. Find the scaling factor for sizing the window.
    Scaling Factor: `[DPI of the monitor after the resolution change.) / 96]`.
    4. Execute ForegroundWndDMProc().
    */
    hmon = MonitorFromWindow(wnd.wnd, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(hmon, (MONITORINFO *)&wnd.mi);
    SetDM(&wnd.dm);
    GetDpiForMonitor(hmon, 0, &dpi, &dpi);
    scale = dpi / 96;
    wnd.cx = wnd.dm.dmPelsWidth * scale;
    wnd.cy = wnd.dm.dmPelsHeight * scale;
    ForegroundWndDMProc();
    return 0;
}