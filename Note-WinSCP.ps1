
#$bin = "C:\WinSCPLibrary\bin\WinSCP.exe"

#Add-Type -Path C:\WinSCPLibrary\bin\WinSCP.dll
$options = New-Object WinSCP.SessionOptions
$options.Protocol = [WinSCP.Protocol]::Sftp
$options.HostName = "address"
$options.UserName = "username"
$options.Password = "password"
$options.SshHostKeyFingerprint = "ssh-dss 1024 00:00:00"

$session = New-Object WinSCP.Session
#$session.DebugLogPath = $DebugLogPath
#$session.SessionLogPath = $SessionLogPath
#$session.AdditionalExecutableArguments = $AdditionalExecutableArguments
#$session.DefaultConfiguration = $DefaultConfiguration
#$session.DisableVersionCheck = $DisableVersionCheck
$session.ExecutablePath = $bin
#$session.IniFilePath = $IniFilePath
    
$session.Open($options)

$transferOptions = New-Object WinSCP.TransferOptions
$transferOptions.TransferMode = [WinSCP.TransferMode]::Automatic
$results = $session.PutFiles("file.txt", "./file.txt", $false, $transferOptions)

$files = $session.ListDirectory(".\")
