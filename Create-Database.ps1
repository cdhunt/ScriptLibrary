##################################

#createdb.ps1
#Creates a new database using our specifications

Param ([string]$hostName = 'localhost', [string]$dbName = 'dbname')
Set-PSdebug -strict

$dbName = $dbName.ToLower()
$userName = $dbName

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')  | out-null
$server = new-object ('Microsoft.SqlServer.Management.Smo.Server') $hostName

$dataFileName = $dbName
$logFileName = $dbName + '_Log'

#File Locations based on current location of the Master DB files
$dataFileLocation = $server.Information.MasterDBPath
$logFileLocation = $server.Information.MasterDBLogPath

#Prod File Locations
#If (! $test) {
	$dataFileLocation = 'D:\Microsoft SQL Server\MSSQL.1\MSSQL\Data'
	$logFileLocation = 'E:\Microsoft SQL Server\MSSQL.1\MSSQL\Data'
#}  # No longer necessary now that all MDFs are on L: in Prod

$dataFilePath = $dataFileLocation + '\' + $dataFileName + '.mdf'
$logFilePath = $logFileLocation + '\' + $logFileName + '.ldf'

# Instantiate the database object and add the filegroups
$db = new-object ('Microsoft.SqlServer.Management.Smo.Database') ($server, $dbName)
$sysfg = new-object ('Microsoft.SqlServer.Management.Smo.FileGroup') ($db, 'PRIMARY')
$db.FileGroups.Add($sysfg)

# Create the file for the system tables
$dbdsysfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($sysfg, $dataFileName)
$sysfg.Files.Add($dbdsysfile)
$dbdsysfile.FileName = $dataFilePath
$dbdsysfile.Size = [double](14.0 * 1024.0) #in KB
$dbdsysfile.GrowthType = 'KB'
$dbdsysfile.Growth = 1024.0
$dbdsysfile.IsPrimaryFile = 'True'
$sysfg.IsDefault = $true

# Create the file for the log
$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($db, $logFileName)
$db.LogFiles.Add($dblfile)
$dblfile.FileName = $logFilePath
$dblfile.Size = [double](6.0 * 1024.0)  #in KB
$dblfile.GrowthType = 'Percent'
$dblfile.Growth = 10.0

# Create the database
$db.Create()  # Catch errors here
$db.script()

$serverLogin = New-Object ('Microsoft.SqlServer.Management.Smo.Login') ($server, $userName)
$serverLogin.DefaultDatabase = $dbName
$serverLogin.LoginType = 'SqlLogin'
$serverLogin.PasswordPolicyEnforced = $false
$serverLogin.Create("password")	# Catch errors here
$serverLogin.Enable()	
$serverLogin.Script()

$dbUser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($db, $serverLogin.Name)
$dbUser.UserType = 'SqlLogin'
$dbUser.Login = $dbUser.Name
$dbUser.Create()	# Catch errors here
$dbUser.AddToRole('db_owner')
$dbUser.Alter()
$dbUser.script()