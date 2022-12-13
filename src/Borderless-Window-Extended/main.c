// Borderless Window Extended
#include <windows.h>
#include <shellscalingapi.h>

// Prototypes

// Structure that contains information on the hooked process' window.
struct WINDOW;

// Set the display mode.
void SetDM(DEVMODE *dm);

// Show a message box regarding about an invalid PID.
void PIDErrorMsgBox();

// Set the window style by getting the current window style and adding additional styles to the current one.
void SetWndStyle(int nIndex, LONG_PTR Style);

// Check if the window is minimized or not for a valid HWND.
BOOL IsMinimized();

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground();

// Wrapper around SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags).
DWORD SetWndPosThread();

// Check if the hooked process is alive or not.
DWORD IsProcAliveThread();

// Hooked process' window's display mode apply and reset.
void ForegroundWndDMProc();

// Make this a global structure so it can be easily accessed by functions.
struct WINDOW
{
    HWND hwnd;        // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;     // HANDLE to the hooked process.
    DEVMODE dm;       // Display mode to be applied when the hooked process' window is in the foreground
    DWORD pid;        // PID of the hooked process & reserved variables.
    MONITORINFOEX mi; // Info of the monitor, the hooked process' window is present on.
    BOOL cds, fg;     // Toggle if ChangeDisplaySettingsEx should called or not & if the hooked process' window is the foreground window or not.
    int cx, cy;       // Hooked process' window client size.
};
struct WINDOW wnd = {.mi.cbSize = sizeof(wnd.mi), .dm.dmSize = sizeof(wnd.dm), .cds = FALSE};

void SetDM(DEVMODE *dm)
{
    ChangeDisplaySettingsEx(wnd.mi.szDevice, dm, NULL, CDS_FULLSCREEN, NULL);
    if (dm == 0)
        ChangeDisplaySettingsEx(wnd.mi.szDevice, 0, NULL, 0, NULL);
}
void PIDErrorMsgBox() { MessageBox(0, "Invaild PID!", "Borderless Windowed Extended", MB_ICONEXCLAMATION); }
void SetWndStyle(int nIndex, LONG_PTR Style) { SetWindowLongPtr(wnd.hwnd, nIndex, GetWindowLongPtr(wnd.hwnd, nIndex) & ~(Style)); }
BOOL IsMinimized()
{
    if (IsWindow(wnd.hwnd))
        return IsIconic(wnd.hwnd);
    return FALSE;
}

BOOL IsProcWndForeground(HWND hwnd)
{
    DWORD pid;
    GetWindowThreadProcessId(hwnd, &pid);
    if (wnd.pid == pid && hwnd != NULL)
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
    while (TRUE)
    {
        SetWindowPos(wnd.hwnd, 0,
                     wnd.mi.rcMonitor.left, wnd.mi.rcMonitor.top,
                     wnd.cx, wnd.cy,
                     SWP_NOACTIVATE |
                         SWP_NOSENDCHANGING |
                         SWP_NOOWNERZORDER |
                         SWP_NOZORDER);
        Sleep(1);
    };
    return TRUE;
}

DWORD IsProcAliveThread()
{
    while (WaitForSingleObject(wnd.hproc, INFINITE) != WAIT_OBJECT_0)
        ;
    CloseHandle(wnd.hproc);
    ExitProcess(0);
    return TRUE;
}

void ForegroundWndDMProc(
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
        wnd.fg = IsProcWndForeground(hwnd) && wnd.cds;
        switch (wnd.fg)
        {
        case TRUE:
            if (IsMinimized())
                ShowWindow(wnd.hwnd, SW_RESTORE);
            SetDM(&wnd.dm);
            wnd.cds = FALSE;
            return;
        case FALSE:
            if (!IsMinimized())
                ShowWindow(wnd.hwnd, SW_MINIMIZE);
            SetDM(0);
            wnd.cds = TRUE;
        }
    };
}

int main(int argc, char *argv[])
{
    CreateThread(0, 0, IsProcAliveThread, NULL, 0, 0);
    CreateThread(0, 0, SetWndPosThread, NULL, 0, 0);
    HMONITOR hmon;
    UINT dpi;
    MSG msg;
    float scale;

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
        wnd.pid = atoi(argv[1]);
        wnd.hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | SYNCHRONIZE, FALSE, wnd.pid);
        if (!wnd.hproc)
        {
            CloseHandle(wnd.hproc);
            PIDErrorMsgBox();
            ExitProcess(1);
        }
        while (!IsProcWndForeground(GetForegroundWindow()))
            Sleep(1);
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
    if (IsZoomed(wnd.hwnd))
        ShowWindow(wnd.hwnd, SW_RESTORE);

    /*
    1. Get the monitor, the window is present on.
    2. Get the DPI set for the monitor after the display resolution change.
    3. Find the scaling factor for sizing the window.
    Scaling Factor: `[DPI of the monitor after the resolution change.) / 96]`.
    4. Set a event hook for EVENT_SYSTEM_FOREGROUND.
    5. Set the window style to borderless.
    */
    hmon = MonitorFromWindow(wnd.hwnd, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(hmon, (MONITORINFO *)&wnd.mi);
    SetDM(&wnd.dm);
    GetDpiForMonitor(hmon, 0, &dpi, &dpi);
    scale = dpi / 96;
    wnd.cx = wnd.dm.dmPelsWidth * scale;
    wnd.cy = wnd.dm.dmPelsHeight * scale;

    SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, 0, ForegroundWndDMProc, 0, 0, WINEVENT_OUTOFCONTEXT);
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    };
    return 0;
}