<#
.SYNOPSIS
    Registers sed.exe in Windows Task Scheduler to run with Administrator privileges at startup/logon.
.DESCRIPTION
    Interactive tools like AutoHotkey / sed.exe cannot run as traditional Windows Services
    due to Windows Session 0 Isolation (services cannot detect hotkeys or manage user windows).
    The standard Windows solution is a Task Scheduler task configured with RunLevel = Highest,
    which starts automatically on logon with full Admin privileges and no UAC prompt.
#>

$TaskName = "SedAHK"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}
$ExePath = Join-Path $ScriptDir "sed.exe"

# Verify sed.exe exists
if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] sed.exe not found at: $ExePath" -ForegroundColor Red
    if ($Host.Name -notmatch "ServerRemoteHost") { Read-Host "Press Enter to exit..." }
    exit 1
}

# Check for Administrator privileges; if not elevated, self-elevate
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges to register Task Scheduler task..." -ForegroundColor Cyan
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -PassThru
    $process.WaitForExit()
    exit $process.ExitCode
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Registering $TaskName at Windows Startup (Admin)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Target Executable : $ExePath"
Write-Host "Working Directory : $ScriptDir"
Write-Host ""

# Action: launch sed.exe with working directory
$Action = New-ScheduledTaskAction `
    -Execute $ExePath `
    -WorkingDirectory $ScriptDir

# Trigger: at logon of the current user, with a 3-second delay to allow Desktop Window Manager / Explorer to initialize
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Trigger.Delay = 'PT3S'

# Principal: current user with Highest (Admin) privileges in interactive session
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

# Settings: run on battery, don't stop on battery, never terminate after 3 days, restart on failure
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -Priority 4 `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

try {
    # Remove older version if present
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Description "Runs sed.exe with Administrator privileges at logon (interactive desktop)." `
        -Force | Out-Null

    Write-Host "[SUCCESS] Task '$TaskName' has been registered successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  - Trigger  : At user logon (3s delay for Explorer/DWM initialization)"
    Write-Host "  - Privileges: Administrator (Run with highest privileges, NO UAC prompt)"
    Write-Host "  - Battery  : Enabled (will not stop or prevent starting on battery)"
    Write-Host "  - Duration : Unlimited (ExecutionTimeLimit = 0)"
    Write-Host ""

    # Start the task now if sed.exe is not already running
    $running = Get-Process -Name "sed" -ErrorAction SilentlyContinue
    if (-not $running) {
        Write-Host "Starting '$TaskName' now..." -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 1
        $running = Get-Process -Name "sed" -ErrorAction SilentlyContinue
        if ($running) {
            Write-Host "[SUCCESS] sed.exe is now running with PID: $($running.Id)" -ForegroundColor Green
        }
    } else {
        Write-Host "sed.exe is already running (PID: $($running.Id)). The scheduled task will start it on next logon." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[ERROR] Failed to register task: $_" -ForegroundColor Red
}

Write-Host ""
if ($Host.Name -notmatch "ServerRemoteHost") {
    Write-Host "Press Enter to exit..."
    Read-Host
}
