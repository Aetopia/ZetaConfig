// Borderless Window Extended
#include <windows.h>
#include <shellscalingapi.h>

// Prototypes

// Set the display mode.
void SetDM(DEVMODE *dm);

// Show a message box regarding about an invalid PID.
void PIDErrorMsgBox();

// Set the window style by getting the current window style and adding additional styles to the current one.
void SetWndStyle(HWND hwnd, int nIndex, LONG_PTR Style);

// Structure that contains information on the hooked process' window.
struct WINDOW;

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground();

// Check for a specific foreground window via its PID and get a handle to the process
void HookForegroundWndProc();

// Check if the hooked process is alive or not.
DWORD IsProcAlive();

// Hooked process' window's display mode apply and reset loop.
void ForegroundWndDMProc();

// Make this global structure so it can be easily accessed by functions.
struct WINDOW
{
    HWND wnd, hwnd;         // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;           // HANDLE to the hooked process.
    DEVMODE *dm;            // Display mode to be applied when the hooked process' window is in the foreground
    BOOL reset;             // Reset the display mode back to default.
    DWORD process, ec, pid; // PID of the hooked process & reserved variables.
    char *monitor;          // Name of the monitor, the window is present on.
    int x, y, cx, cy;       // Hooked process' window position and size.
};
struct WINDOW wnd;

void SetDM(DEVMODE *dm)
{
    ChangeDisplaySettingsEx(wnd.monitor, dm, NULL, CDS_FULLSCREEN, NULL);
    if (dm == 0)
    {
        ChangeDisplaySettingsEx(wnd.monitor, 0, NULL, 0, NULL);
    };
}
void PIDErrorMsgBox() { MessageBox(0, "Invaild PID!", "Borderless Windowed Extended", MB_ICONEXCLAMATION); }
void SetWndStyle(HWND hwnd, int nIndex, LONG_PTR Style) { SetWindowLongPtr(hwnd, nIndex, GetWindowLongPtr(hwnd, nIndex) & ~(Style)); }

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
    do
    {
    } while (!!IsProcWndForeground());
}

DWORD IsProcAlive()
{
    do
    {
        Sleep(1);
        if (GetExitCodeProcess(wnd.hproc, &wnd.ec) &&
            (wnd.ec != STILL_ACTIVE || IsHungAppWindow(wnd.wnd)))
        {
            if (wnd.reset)
            {
                SetDM(0);
            };
            CloseHandle(wnd.hproc);
            ExitProcess(0);
        };
        SetWindowPos(wnd.wnd, 0,
                     wnd.x, wnd.y,
                     wnd.cx, wnd.cy,
                     SWP_NOACTIVATE |
                         SWP_NOSENDCHANGING |
                         SWP_NOOWNERZORDER |
                         SWP_NOZORDER);
    } while (TRUE);
    return TRUE;
}

void ForegroundWndDMProc()
{
    do
    {
        // Switch back to native display resolution.
        wnd.reset = TRUE;
        do
        {
        } while (!IsProcWndForeground());
        if (!IsIconic(wnd.wnd))
            ShowWindow(wnd.wnd, SW_MINIMIZE);
        SetDM(0);

        // Switch to the desired display resolution.
        wnd.reset = FALSE;
        do
        {
        } while (IsProcWndForeground());
        if (IsIconic(wnd.wnd))
            ShowWindow(wnd.wnd, SW_RESTORE);
        SetDM(wnd.dm);
    } while (TRUE);
}

int main(int argc, char *argv[])
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    DEVMODE dm;
    MONITORINFOEX mi;
    HMONITOR hmon;
    UINT dpia, dpib;
    float scale;
    mi.cbSize = sizeof(mi);
    dm.dmSize = sizeof(dm);

    if (argc != 4)
    {
        MessageBox(0,
                   "BWEx.exe <PID> <Width> <Height>",
                   "Borderless Windowed Extended",
                   MB_ICONINFORMATION);
        return 0;
    };

    // Setup the DEVMODE structure.
    dm.dmPelsWidth = atoi(argv[2]);
    dm.dmPelsHeight = atoi(argv[3]);
    dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT;
    wnd.dm = &dm;

    // Check if specified resolution is valid or not.
    if (ChangeDisplaySettings(wnd.dm, CDS_TEST) != DISP_CHANGE_SUCCESSFUL ||
        (dm.dmPelsWidth || dm.dmPelsHeight) == 0)
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
        // Create a thread that checks if the process is alive or not.
        CreateThread(0, 0, IsProcAlive, NULL, 0, 0);
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
    */

    // Restore the window if its maximized.
    if (IsZoomed(wnd.wnd))
        ShowWindow(wnd.wnd, SW_RESTORE);

    // Set the window style to borderless.
    SetWndStyle(wnd.wnd, GWL_STYLE, WS_OVERLAPPEDWINDOW);
    SetWndStyle(wnd.wnd, GWL_EXSTYLE, WS_EX_DLGMODALFRAME | WS_EX_COMPOSITED | WS_EX_OVERLAPPEDWINDOW | WS_EX_LAYERED | WS_EX_STATICEDGE | WS_EX_TOOLWINDOW | WS_EX_APPWINDOW | WS_EX_TOPMOST);

    /*
    Get the monitor, the window is present on.
    1. Get the currently set DPI for the monitor, the window launches.
    2. Store monitor name and new window position coordinates to the WINDOW structure.
    */
    hmon = MonitorFromWindow(wnd.wnd, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(hmon, (MONITORINFO *)&mi);
    GetDpiForMonitor(hmon, 0, &dpia, &dpia);
    wnd.monitor = mi.szDevice;
    wnd.x = mi.rcMonitor.left;
    wnd.y = mi.rcMonitor.top;

    /*
    Size the window based on the DPI scaling set by the desired display resolution and execute ForegroundWndDMProc().
    1. Get the DPI set for the monitor after the display resolution change.
    2. Find the scaling factor for sizing the window.
    Scaling Factor: [DPI A (DPI of the monitor before the resolution change.) / DPI B (DPI of the monitor after resolution change.)]`.
    3. Create a new thread that calls SetWndPosThread(LPVOID args) to set and maintain the window size & position.
    */
    SetDM(wnd.dm);
    GetDpiForMonitor(hmon, 0, &dpib, &dpib);
    scale = dpia / dpib;
    wnd.cx = dm.dmPelsWidth * scale;
    wnd.cy = dm.dmPelsHeight * scale;
    ForegroundWndDMProc();
    return 0;
}