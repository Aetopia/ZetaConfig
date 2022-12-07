// Source code for Window Display Mode Tool.
#include <windows.h>
#include <libgen.h>
#include <psapi.h>
#include <shellscalingapi.h>
#include <stdio.h>

// Prototypes

// Structure that contains information on the hooked process' window.
struct WINDOW;

// Check if the current foreground window is the hooked process' window.
BOOL IsProcWndForeground(struct WINDOW *wnd);

void SetWndStyle(struct WINDOW *wnd);

// Check for a specific foreground window via its PID and once hooked, set the display mode.
void CheckForegroundWndPID(struct WINDOW *wnd);

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
    HWND pwnd, hwnd;   // HWND of the hooked process's window & reserved HWND variable.
    HANDLE hproc;      // HANDLE to the hooked process.
    DEVMODE *dm;       // Display mode to be applied when the hooked process' window is in the foreground
    BOOL reset;        // Reset the display mode back to default.
    DWORD id, ec, pid; // PID of the hooked process & reserved variables.
    int cx, cy, x, y;
    char *monitor, *name; // Name of the monitor, the window is present on & name of the process.
};

BOOL IsProcWndForeground(struct WINDOW *wnd)
{
    wnd->hwnd = GetForegroundWindow();
    GetWindowThreadProcessId(wnd->hwnd, &wnd->pid);
    if (wnd->id == wnd->pid && wnd->hwnd != 0)
    {
        if (wnd->pwnd != wnd->hwnd)
        {
            wnd->pwnd = wnd->hwnd;
            SetWndBorderless(wnd);
        }
        return FALSE;
    };
    return TRUE;
}

void SetWndStyle(struct WINDOW *wnd)
{
    SetWindowLongPtr(wnd->pwnd, GWL_STYLE,
                     GetWindowLongPtr(wnd->pwnd, GWL_STYLE) &
                         ~(WS_OVERLAPPEDWINDOW));
    SetWindowLongPtr(wnd->pwnd, GWL_EXSTYLE,
                     GetWindowLongPtr(wnd->pwnd, GWL_EXSTYLE) &
                         ~(WS_EX_DLGMODALFRAME |
                           WS_EX_COMPOSITED |
                           WS_EX_OVERLAPPEDWINDOW |
                           WS_EX_LAYERED |
                           WS_EX_STATICEDGE |
                           WS_EX_TOOLWINDOW |
                           WS_EX_APPWINDOW |
                           WS_EX_TOPMOST));
    SetWindowPos(wnd->pwnd,
                 0,
                 wnd->x,
                 wnd->y,
                 wnd->cx,
                 wnd->cy,
                 SWP_FRAMECHANGED);
}

void CheckForegroundWndPID(struct WINDOW *wnd)
{
    wnd->hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, wnd->id);
    if (!wnd->hproc)
    {
        CloseHandle(wnd->hproc);
        MessageBox(0,
                   "Invaild PID!",
                   "Window Display Mode Tool",
                   MB_ICONEXCLAMATION);
        exit(1);
    }
    do
    {
        IsProcAlive(wnd);
    } while (!!IsProcWndForeground(wnd));
}

void CheckForegroundWndProc(struct WINDOW *wnd)
{
    char file[MAX_PATH];
    for (;;)
    {
        wnd->pwnd = GetForegroundWindow();
        GetWindowThreadProcessId(wnd->pwnd, &wnd->id);
        wnd->hproc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, wnd->id);
        GetModuleFileNameEx(wnd->hproc, 0, file, MAX_PATH);
        if (strcmp(strlwr(basename(file)), wnd->name) == 0)
        {
            break;
        }
        CloseHandle(wnd->hproc);
    }
}

void IsProcAlive(struct WINDOW *wnd)
{
    GetExitCodeProcess(wnd->hproc, &wnd->ec);
    if (wnd->ec != STILL_ACTIVE)
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
    printf("Check!\n");
    do
    {
        IsProcAlive(wnd);
    } while (IsProcWndForeground(wnd));
    do
    {
        ShowWindow(wnd->pwnd, SW_RESTORE);
    } while (IsIconic(wnd->pwnd) &&
             IsWindow(wnd->pwnd));
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
    printf("Uncheck!\n");
    do
    {
        IsProcAlive(wnd);
    } while (!IsProcWndForeground(wnd));
    do
    {
        ShowWindow(wnd->pwnd, SW_MINIMIZE);
    } while (!IsIconic(wnd->pwnd) &&
             IsWindow(wnd->pwnd) &&
             !SetForegroundWindow(FindWindow("Shell_TrayWnd", NULL)));
    ChangeDisplaySettingsEx(wnd->monitor,
                            0,
                            NULL,
                            CDS_FULLSCREEN,
                            NULL);
    ChangeDisplaySettingsEx(wnd->monitor, 0, NULL, 0, NULL);
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
                   "WDMT.exe <PID> <Width> <Height>",
                   "Window Display Mode Tool",
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
                   "Window Display Mode Tool",
                   MB_ICONEXCLAMATION);
        return 1;
    }

    // Check if the <PID/Process> argument contains only integers or not.
    if (strspn(argv[1], "0123456789") == strlen(argv[1]))
    {
        wnd.id = atoi(argv[1]);
        CheckForegroundWndPID(&wnd);
    }
    else
    {
        wnd.name = strlwr(argv[1]);
        CheckForegroundWndProc(&wnd);
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
    wnd.x = mi.rcMonitor.left;
    wnd.y = mi.rcMonitor.top;

    // If the specified resolution is not the same as the display native resolution then execute ResetForegroundWndDM(struct WINDOW *wnd).
    // This code block additionally sizes the window based on the DPI scaling set by the desired display resolution.
    if (ChangeDisplaySettingsEx(mi.szDevice, wnd.dm, NULL, CDS_FULLSCREEN, NULL) == DISP_CHANGE_SUCCESSFUL)
    {
        GetDpiForMonitor(hmon, 0, &dpiX, &dpiY);
        wnd.cx = dm.dmPelsWidth * (float)dpiC / dpiX;
        wnd.cy = dm.dmPelsHeight * (float)dpiC / dpiY;
        SetWndStyle(&wnd);
        ResetForegroundWndDM(&wnd);
    };
    return 0;
}
