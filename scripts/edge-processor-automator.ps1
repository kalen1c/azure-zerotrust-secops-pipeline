# Execute edge processor
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\ProgramData\Honeypot_Logger.ps1"'

# Execute every 5 minutes
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)

# Run at highest priviledges
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName "Honeypot_Automater" -Action $Action -Trigger $Trigger -Principal $Principal -Description "Automates Powershell Edge Processor script every 5 minutes"
