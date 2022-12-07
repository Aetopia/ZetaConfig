#include <windows.h>
#include <stdio.h>
#include <unistd.h>

BOOL WINAPI DllMain(__attribute__((unused)) HINSTANCE hInstDll, DWORD fwdreason, __attribute__((unused)) LPVOID lpReserved)
{
    if (fwdreason == DLL_PROCESS_ATTACH)
    {
        FILE *f;
        int sz, pid = GetCurrentProcessId();
        char *res, *cmd;
        if (access("BWEx.txt", F_OK) != 0)
        {
            f = fopen("BWEx.txt", "w");
            fprintf(f, "0 0");
            fclose(f);
        };
        f = fopen("BWEx.txt", "r");
        fseek(f, 0, SEEK_END);
        sz = ftell(f);
        res = malloc(sz);
        fseek(f, 0, SEEK_SET);
        fread(res, sizeof(res), sz, f);
        fclose(f);

        sz = strlen(res) + snprintf(NULL, 0, "%d", pid) + 2;
        cmd = malloc(sz);
        snprintf(cmd, sz, "%d %s", pid, res);
        free(res);
        ShellExecute(0, "open", "BWEx.exe", cmd, ".", 0);
        free(cmd);
    };
    return TRUE;
}
