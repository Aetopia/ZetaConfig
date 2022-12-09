// Borderless Window Extended
#include <windows.h>
#include <psapi.h>

// Prototypes

// Set the display mode.
void SetDM(char *monitor, DEVMODE *dm);

// Show a message box regarding about an invalid PID.
void PIDErrorMsgBox();

// Set the window style by getting the current window style and adding additional styles to the current one.
void SetWndStyle(HWND hwnd, int nIndex, LONG_PTR Style);

// Structure that contains information on the hooked process' window.
struct WINDOW;

// A thread that wraps SetWindowPos (HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags).
DWORD SetWndPosThread(LPVOID args);

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground(struct WINDOW *wnd);

// Check for a specific foreground window via its PID and get a handle to the process
void HookForegroundWndProc(struct WINDOW *wnd);

// Check if the hooked process is alive or not.
DWORD IsProcAlive(LPVOID args);

// Hooked process' window's display mode apply and reset loop.
void ForegroundWndDMProc(struct WINDOW *wnd);

struct WINDOW
{
    HWND pwnd, hwnd;        // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;           // HANDLE to the hooked process.
    DEVMODE *dm;            // Display mode to be applied when the hooked process' window is in the foreground
    BOOL reset;             // Reset the display mode back to default.
    DWORD process, ec, pid; // PID of the hooked process & reserved variables.
    char *monitor;          // Name of the monitor, the window is present on.
    int x, y, cx, cy;       // Hooked process' window position.
};

void SetDM(char *monitor, DEVMODE *dm)
{
    ChangeDisplaySettingsEx(monitor, dm, NULL, CDS_FULLSCREEN, NULL);
    if (dm == 0)
    {
        ChangeDisplaySettingsEx(monitor, 0, NULL, 0, NULL);
    };
}
void PIDErrorMsgBox() { MessageBox(0, "Invaild PID!", "Borderless Windowed Extended", MB_ICONEXCLAMATION); }
void SetWndStyle(HWND hwnd, int nIndex, LONG_PTR Style) { SetWindowLongPtr(hwnd, nIndex, GetWindowLongPtr(hwnd, nIndex) & ~(Style)); }

DWORD SetWndPosThread(LPVOID args)
{
    struct WINDOW *wnd = (struct WINDOW *)args;
    do
    {
        Sleep(1);
        SetWindowPos(wnd->pwnd, 0,
                     wnd->x, wnd->y,
                     wnd->cx, wnd->cy,
                     SWP_ASYNCWINDOWPOS | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    } while (TRUE);
    return 0;
}

BOOL IsProcWndForeground(struct WINDOW *wnd)
{
    wnd->hwnd = GetForegroundWindow();
    GetWindowThreadProcessId(wnd->hwnd, &wnd->pid);
    if (wnd->process == wnd->pid && wnd->hwnd != 0)
    {
        if (wnd->pwnd != wnd->hwnd)
        {
            wnd->pwnd = wnd->hwnd;
        };
        return FALSE;
    };
    return TRUE;
}

void HookForegroundWndProc(struct WINDOW *wnd)
{
    wnd->hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, wnd->process);
    if (!wnd->hproc)
    {
        CloseHandle(wnd->hproc);
        PIDErrorMsgBox();
        exit(1);
    }
    // Create a thread that checks if the process is alive or not.
    CreateThread(0, 0, IsProcAlive, (LPVOID)wnd, 0, 0);
    do
    {
        Sleep(1);
    } while (!!IsProcWndForeground(wnd));
}

DWORD IsProcAlive(LPVOID args)
{
    struct WINDOW *wnd = (struct WINDOW *)args;
    do
    {
        Sleep(1);
        if (GetExitCodeProcess(wnd->hproc, &wnd->ec) && (wnd->ec != STILL_ACTIVE || IsHungAppWindow(wnd->pwnd)))
        {
            CloseHandle(wnd->hproc);
            if (wnd->reset)
            {
                SetDM(wnd->monitor, 0);
            };
            exit(0);
        };
    } while (TRUE);
    return 0;
}

void ForegroundWndDMProc(struct WINDOW *wnd)
{
    do
    {
        // Switch back to native display resolution.
        wnd->reset = TRUE;
        do
        {
            Sleep(1);
        } while (!IsProcWndForeground(wnd));
        do
        {
            ShowWindow(wnd->pwnd, SW_MINIMIZE);
        } while (!IsIconic(wnd->pwnd) &&
                 !SetForegroundWindow(FindWindow("Shell_TrayWnd", NULL)));
        SetDM(wnd->monitor, 0);

        // Switch to the desired display resolution.
        wnd->reset = FALSE;
        do
        {
            Sleep(1);
        } while (IsProcWndForeground(wnd));
        do
        {
            ShowWindow(wnd->pwnd, SW_RESTORE);
        } while (IsIconic(wnd->pwnd));
        SetDM(wnd->monitor, wnd->dm);
    } while (TRUE);
}

int main(int argc, char *argv[])
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    struct WINDOW wnd;
    DEVMODE dm;
    MONITORINFOEX mi;
    int scale;
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
        HookForegroundWndProc(&wnd);
        scale = GetDpiForWindow(wnd.pwnd) / 96;
    }
    else
    {
        PIDErrorMsgBox();
        return 1;
    };

    /* References:
    https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
    https://github.com/Codeusa/Borderless-Gaming/blob/74b19ecebc4bae4df1fbb1776ec7c5d69d4e0d0c/BorderlessGaming.Logic/Windows/Manipulation.cs#L72
    */

    // Restore the window if its maximized.
    do
    {
        ShowWindow(wnd.pwnd, SW_RESTORE);
    } while (IsZoomed(wnd.pwnd));

    // Set the window style to borderless.
    SetWndStyle(wnd.pwnd, GWL_STYLE, WS_OVERLAPPEDWINDOW);
    SetWndStyle(wnd.pwnd, GWL_EXSTYLE, WS_EX_DLGMODALFRAME | WS_EX_COMPOSITED | WS_EX_OVERLAPPEDWINDOW | WS_EX_LAYERED | WS_EX_STATICEDGE | WS_EX_TOOLWINDOW | WS_EX_APPWINDOW | WS_EX_TOPMOST);

    // Get the monitor, the window is present on.;
    GetMonitorInfo(MonitorFromWindow(wnd.pwnd, MONITOR_DEFAULTTONEAREST), (MONITORINFO *)&mi);
    wnd.monitor = mi.szDevice;
    wnd.x = mi.rcMonitor.left;
    wnd.y = mi.rcMonitor.top;

    // Size the window based on the DPI scaling set by the desired display resolution.
    SetDM(mi.szDevice, wnd.dm);
    wnd.cx = dm.dmPelsWidth * scale;
    wnd.cy = dm.dmPelsHeight * scale;

    CreateThread(0, 0, SetWndPosThread, (LPVOID)&wnd, 0, 0);
    ForegroundWndDMProc(&wnd);
    return 0;
}