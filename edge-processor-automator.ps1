# Executes edge processor
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\ProgramData\Honeypot_Logger.ps1"'

# Executes every 5 minutes
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)

# Runs it at highest priviledges
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Registers the task
Register-ScheduledTask -TaskName "Honeypot_Automater" -Action $Action -Trigger $Trigger -Principal $Principal -Description "Automates Powershell Edge Processor script every 5 minutes"
