<#
.SYNOPSIS
    Removes the SedAHK startup task from Windows Task Scheduler.
#>

$TaskName = "SedAHK"

# Check for Administrator privileges; if not elevated, self-elevate
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges to remove Task Scheduler task..." -ForegroundColor Cyan
    $process = Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -PassThru
    $process.WaitForExit()
    exit $process.ExitCode
}

try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    Write-Host "[SUCCESS] Task '$TaskName' removed successfully." -ForegroundColor Green
}
catch {
    Write-Host "[INFO] Task '$TaskName' was not found or has already been removed." -ForegroundColor Yellow
}

Write-Host ""
if ($Host.Name -notmatch "ServerRemoteHost") {
    Write-Host "Press Enter to exit..."
    Read-Host
}
