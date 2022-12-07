// Borderless Window Extended
#include <windows.h>
#include <libgen.h>
#include <psapi.h>
#include <shellscalingapi.h>

// Prototypes

// Structure that contains information on the hooked process' window.
struct WINDOW;

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground(struct WINDOW *wnd);

// Check for a specific foreground window via its PID and once hooked, set the display mode.
void HookForegroundWnd(struct WINDOW *wnd);

// Check if the hooked process is alive or not.
void IsProcAlive(struct WINDOW *wnd);

// Check the hooked process is alive.
void IsWndProcAlive(struct WINDOW *wnd);

// Apply the desired resolution when the hooked process is in the foreground.
void SetForegroundWndDM(struct WINDOW *wnd);

// Reset to the native resolution when the hooked process is not in the foreground.
void ResetForegroundWndDM(struct WINDOW *wnd);

struct WINDOW
{
    HWND pwnd, hwnd;        // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;           // HANDLE to the hooked process.
    DEVMODE *dm;            // Display mode to be applied when the hooked process' window is in the foreground
    BOOL reset;             // Reset the display mode back to default.
    DWORD process, ec, pid; // PID of the hooked process & reserved variables.
    char *monitor;          // Name of the monitor, the window is present on.
};

BOOL IsProcWndForeground(struct WINDOW *wnd)
{
    wnd->hwnd = GetForegroundWindow();
    GetWindowThreadProcessId(wnd->hwnd, &wnd->pid);
    if (wnd->process == wnd->pid && wnd->hwnd != 0)
    {
        if (wnd->pwnd != wnd->hwnd)
        {
            wnd->pwnd = wnd->hwnd;
        }
        return FALSE;
    };
    return TRUE;
}

void HookForegroundWnd(struct WINDOW *wnd)
{
    wnd->hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, wnd->process);
    if (!wnd->hproc)
    {
        CloseHandle(wnd->hproc);
        MessageBox(0,
                   "Invaild PID!",
                   "Borderless Windowed Extended",
                   MB_ICONEXCLAMATION);
        exit(1);
    }
    do
    {
        IsProcAlive(wnd);
    } while (!!IsProcWndForeground(wnd));
}

void IsProcAlive(struct WINDOW *wnd)
{
    GetExitCodeProcess(wnd->hproc, &wnd->ec);
    if (wnd->ec != STILL_ACTIVE || IsHungAppWindow(wnd->pwnd))
    {
        CloseHandle(wnd->hproc);
        for (;;)
        {
            if (wnd->reset)
            {
                if (ChangeDisplaySettingsEx(wnd->monitor,
                                            0,
                                            NULL,
                                            CDS_FULLSCREEN,
                                            NULL) == DISP_CHANGE_SUCCESSFUL)
                {
                    ChangeDisplaySettingsEx(wnd->monitor, 0, NULL, 0, NULL);
                    exit(0);
                };
            };
            exit(0);
        };
        Sleep(1);
    };
}

void SetForegroundWndDM(struct WINDOW *wnd)
{
    wnd->reset = FALSE;
    do
    {
        IsProcAlive(wnd);
    } while (IsProcWndForeground(wnd));
    do
    {
        ShowWindow(wnd->pwnd, SW_RESTORE);
    } while (IsIconic(wnd->pwnd) && IsWindow(wnd->pwnd));
    ChangeDisplaySettingsEx(wnd->monitor,
                            wnd->dm,
                            NULL,
                            CDS_FULLSCREEN,
                            NULL);
    ResetForegroundWndDM(wnd);
}

void ResetForegroundWndDM(struct WINDOW *wnd)
{
    wnd->reset = TRUE;
    do
    {
        IsProcAlive(wnd);
    } while (!IsProcWndForeground(wnd));
    ChangeDisplaySettingsEx(wnd->monitor,
                            0,
                            NULL,
                            CDS_FULLSCREEN,
                            NULL);
    ChangeDisplaySettingsEx(wnd->monitor, 0, NULL, 0, NULL);
    do
    {
        ShowWindow(wnd->pwnd, SW_MINIMIZE);
    } while (!IsIconic(wnd->pwnd) &&
             IsWindow(wnd->pwnd) &&
             !SetForegroundWindow(FindWindow("Shell_TrayWnd", NULL)));
    SetForegroundWndDM(wnd);
}

int main(int argc, char *argv[])
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    struct WINDOW wnd;
    DEVMODE dm;
    MONITORINFOEX mi;
    HMONITOR hmon;
    UINT dpiX, dpiY, dpiC = GetDpiForSystem();
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

    // Check if the <PID/Process> argument contains only integers or not.
    if (strspn(argv[1], "0123456789") == strlen(argv[1]))
    {
        wnd.process = atoi(argv[1]);
        HookForegroundWnd(&wnd);
    }
    else
    {
        MessageBox(0,
                   "Invaild PID!",
                   "Borderless Windowed Extended",
                   MB_ICONEXCLAMATION);
        return 1;
    };

    // Source: https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353
    // Restore the window if its maximized.
    do
    {
        ShowWindow(wnd.pwnd, SW_RESTORE);
    } while (IsZoomed(wnd.pwnd));

    // Get the monitor, the window is present on.
    hmon = MonitorFromWindow(wnd.pwnd, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(hmon, (MONITORINFO *)&mi);
    wnd.monitor = mi.szDevice;

    // Set the window style to borderless and reposition the window.
    // Source: https://github.com/Codeusa/Borderless-Gaming/blob/74b19ecebc4bae4df1fbb1776ec7c5d69d4e0d0c/BorderlessGaming.Logic/Windows/Manipulation.cs#L72
    SetWindowPos(wnd.pwnd, 0, mi.rcMonitor.left, mi.rcMonitor.top, 0, 0, SWP_NOSIZE);
    SetWindowLongPtr(wnd.pwnd, GWL_STYLE,
                     GetWindowLongPtr(wnd.pwnd, GWL_STYLE) &
                         ~(WS_OVERLAPPEDWINDOW));
    SetWindowLongPtr(wnd.pwnd, GWL_EXSTYLE,
                     GetWindowLongPtr(wnd.pwnd, GWL_EXSTYLE) &
                         ~(WS_EX_DLGMODALFRAME |
                           WS_EX_COMPOSITED |
                           WS_EX_OVERLAPPEDWINDOW |
                           WS_EX_LAYERED |
                           WS_EX_STATICEDGE |
                           WS_EX_TOOLWINDOW |
                           WS_EX_APPWINDOW |
                           WS_EX_TOPMOST));

    // Size the window based on the DPI scaling set by the desired display resolution.
    ChangeDisplaySettingsEx(mi.szDevice, wnd.dm, NULL, CDS_FULLSCREEN, NULL);
    GetDpiForMonitor(hmon, 0, &dpiX, &dpiY);
    SetWindowPos(wnd.pwnd, 0, 0, 0,
                 dm.dmPelsWidth * (float)dpiC / dpiX,
                 dm.dmPelsHeight * (float)dpiC / dpiY,
                 SWP_FRAMECHANGED | SWP_NOREPOSITION);
    ResetForegroundWndDM(&wnd);
    return 0;
}