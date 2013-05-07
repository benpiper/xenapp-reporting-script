
Summary:

This PowerShell script emails a formatted report with two sections:
* Key health information for online XenApp servers, including name, load evaluator, load, uptime, and sessions.
* Information on user sessions, including username, applications, and client version



Requirements:
* Windows PowerShell
* Citrix XenApp PowerShell SDK


Configuration:

The script takes the following configuration variables:

$zonenames = "Zone1","Zone2"			# Zone names

$wgname = "Production"					# Worker group name to check for offline servers

$smtpserver = "1.2.3.4"					# SMTP Server

$mailfrom = "xenapp@benpiper.com"		# SMTP Mail From Address

$mailto = "alerts@benpiper.com"			# SMTP Mail To Address

$mailcc = "collector@benpiper.com"		# SMTP CC To Address

$mailsubject = "XenApp Health Check"	# Subject Line


An sample configuration script is provided in "xareport-config.ps1.txt". Rename the sample file or copy these variables to a separate configuration PowerShell script called "xareport-config.ps1" and customize them according to your needs.

Tip: You can create multiple configuration files for testing and simply reassign the $configFile variable in the main script to the path and filename of the configuration script you wish to use.