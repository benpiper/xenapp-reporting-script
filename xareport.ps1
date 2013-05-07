########################################################################################################################
#
# XenApp 6 Reporting Script
# Created 7-20-2011 by Ben Piper
# Modified 5-7-2013
#
# Summary:
#	* Enumerates online XenApp servers (name, uptime, sessions, ip, load, load evaluator)
#	* Enumerates active user sessions (username, application, logon time, session state, server name, client version)
#	* Sends an email with the preceding information in a formatted report
#	* Sends an email alert if any servers in a specified worker group ($wgname) are offline
#
########################################################################################################################
#
# Initialization of XenApp snapin and variables
#
########################################################################################################################

# Specify the full path to the script containing the configuration variables (see README.md for help)
$configFile = "./xareport-config.ps1"

# Check for the configuration file

If ((Test-Path -path $configFile) -eq $True) {
	. $configFile
	}
else {
	Write-Host Configuration file $configFile not found. Exiting...
	break
	}

Add-PSSnapin "Citrix.XenApp.Commands"


########################################################################################################################
#
# Functions
#
########################################################################################################################

# Convert client string to a meaningful version
# 	Format is: buildNumber {"meaningful-version-string"; break}  

function convertToVersion($build) {
	switch($build){
		9200 {"RDP 6.2"; break}  89 {"13.1"; break}  25 {"13.4.0.25"; break}  22 {"13.1.2"; break}  8 {"12.3"; break}  55 {"13.3.0.55"; break}  6685 {"13.0"; break}  30 {"12.1"; break}  6 {"12.0.3"; break}  6410 {"12.0"; break}  142{"Java"; break}  317{"3.0"; break}  324{"3.0"; break}  330{"3.0"; break}  349{"3.0"; break}  304{"MAC 6.3"; break}  314{"MAC 6.3"; break}  323{"MAC 6.3"; break}  326{"MAC 6.3"; break}  400{"MAC 7.0"; break}  402{"MAC 7.0"; break}  405{"MAC 7.0"; break}  406{"MAC 7.0"; break}  407{"MAC 7.0"; break}  402{"MAC 7.0"; break}  411{"MAC 7.0"; break}  500{"MAC 7.1"; break}  600{"MAC 10.0"; break}  601{"MAC 10.0"; break}  581{"4.0"; break}  606{"4.0"; break}  609{"4.0"; break}  614{"4.0"; break}  686{"4.0"; break}  715{"4.2"; break}  727{"4.2"; break}  741{"4.2"; break}  779{"4.21"; break}  730{"wyse1200le"; break}  910{"6.0"; break}  931{"6.0"; break}  961{"6.01"; break}  963{"6.01"; break}  964{"6.01"; break}  967{"6.01"; break}  985{"6.2"; break}  986{"6.2"; break}  1041{"7.0"; break}  1050{"6.3"; break}  1051{"6.31"; break}  1414{"Java 7.0"; break}  1679{"Java 8.1"; break}  1868{"Java 9.4"; break}  1876{"Java 9.5"; break}  2600{"RDP 5.01"; break}  2650{"10.2"; break}  3790{"RDP 5.2"; break}  6000{"RDP 6.0"; break}  2650{"10.2"; break}  5284{"11.0"; break}  5323{"11.0"; break}  5357{"11.0"; break}  6001{"RDP 6.0"; break}  8292{"10.25"; break}  10359{"10.13"; break}  128b1{"MAC 10.0"; break}  12221{"Linux 10.x"; break}  13126{"Solaris 7.0"; break}  17106{"7.0"; break}  17534{"7.0"; break}  20497{"7.01"; break}  21825{"7.10"; break}  21845{"7.1"; break}  22650{"7.1"; break}  24737{"8.0"; break}  26449{"8.0"; break}  26862{"8.01"; break}  28519{"8.05"; break}  29670{"8.1"; break}  30817{"8.26"; break}  31327{"9.0"; break}  31560{"11.2"; break}  32649{"9.0"; break}  32891{"9.0"; break}  34290{"8.4"; break}  35078{"9.0"; break}  36280{"9.1"; break}  36824{"9.02 WinCE"; break}  37358{"9.04"; break}  39151{"9.15"; break}  44236{"9.15 WinCE"; break}  44367{"9.2"; break}  44376{"9.2"; break}  44467{"Linux 10.0"; break}  45418{"10.0"; break}  46192{"9.18 WinCE"; break}  49686{"10.0"; break}  50123{"Linux 10.6"; break}  50211{"9.230"; break}  52110{"10.0"; break}  52504{"9.2"; break}  53063{"9.237"; break}  55362{"10.08"; break}  55836{"10.1"; break}  58643{"10.15"; break}  1{"12.1.44"; break}
		default {$build; break}
	}
}



########################################################################################################################
#
# Main Program
#
########################################################################################################################

# Get information from XenApp servers

$servers = Get-XAServer -OnlineOnly -ZoneName $zonenames | Sort-Object -Property ServerName
$reportObj = @()
foreach ($server in $servers) {
	
	# Get sessions, excluding sessions 1 (Console) and 65536 (Listening)
	$sessions = get-xasession -servername $server | Where {$_.State -ne "Listening"} | Where {$_.SessionName -ne "Console"} | sort -unique | Measure-Object
	
	$reportObj += new-object psobject -Property @{
		
		IP = [string]$server.IPAddresses
		LoadEvaluator = Get-XALoadEvaluator -servername $server
		Uptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime((gwmi win32_operatingSystem -computer $server).lastbootuptime)
		Sessions = $sessions.Count
		ServerName = $server.ServerName
		Load = Get-XAServerLoad -servername $server
	}	
}


# Get information from sessions

$sessions = @()
foreach($session in Get-XASession -full | where {$_.sessionid -gt 1 -and $_.sessionid -lt 65536}) {
	$sessions += new-object psobject -Property @{
		User = $session.accountname
		BrowserName = $session.browsername
		LogonTime = $session.logontime
		State = $session.state
		ServerName = $session.servername
		Client = convertToVersion($session.clientbuildnumber)
	}
}


# Generate the report and email it

$reportsessions = $sessions | sort-object -Property LogonTime | convertto-html -Property User,BrowserName,LogonTime,State,ServerName,Client -fragment
$reporthtml = $reportobj | ConvertTo-HTML -Property ServerName,Uptime,Sessions,IP,Load,LoadEvaluator
$reporthtml += $reportsessions
Send-MailMessage -smtpserver $smtpserver -To $mailto -CC $mailcc -From $mailfrom -Subject $mailsubject -body "$reporthtml" -BodyAsHTML


# Send an email if any servers in the $wgname worker group are offline

$wgservers = (Get-XAWorkerGroup | where {$_.workergroupname -eq "$wgname"}).servernames | sort
$difference = compare -ReferenceObject $wgservers -DifferenceObject $servers -excludedifferent -includeequal
if ($difference.length -ne $wgservers.length) {
	Send-MailMessage -smtpserver $smtpserver -To $mailto -CC $mailcc -From $mailfrom -Subject "XenApp Server Offline" -body "A XenApp server in the worker group $wgname is offline." -BodyAsHTML
	}