# sed_ahk

**sed.ahk**
makes window management bearable
This script utilizes [`VirtualDesktopAccessor`](https://github.com/Ciantic/VirtualDesktopAccessor) to interact with Windows Virtual Desktops through native DLL calls.

## Running at Startup with Admin Privileges

Because `sed.exe` is an interactive window manager that captures hotkeys and moves windows across virtual desktops, it cannot be run as a traditional Windows Service (Windows Session 0 isolation prevents services from capturing keystrokes or accessing user desktops).

Instead, it is configured to run at logon via **Windows Task Scheduler** with **Highest Privileges** (`RunLevel = Highest`). This provides full administrator rights without any UAC prompts on startup.

### Installation
- Double-click [`install_startup.bat`](file:///C:/Users/adharsh/Documents/sed_ahk/install_startup.bat) (or run [`install_task.ps1`](file:///C:/Users/adharsh/Documents/sed_ahk/install_task.ps1) in PowerShell) and accept the UAC prompt.

### Uninstallation
- Double-click [`uninstall_startup.bat`](file:///C:/Users/adharsh/Documents/sed_ahk/uninstall_startup.bat) (or run [`uninstall_task.ps1`](file:///C:/Users/adharsh/Documents/sed_ahk/uninstall_task.ps1) in PowerShell).
