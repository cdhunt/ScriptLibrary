Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell"

Initialize-AWSDefaults -StoredCredentials user -Region us-east-1

[string]$BucketName = "bucket"
[string]$RootLocalPath = "C:\Projects\"

$SourceFiles = Get-ChildItem $RootLocalPath -Recurse -File
$S3Files = Get-S3Object -BucketName $BucketName

$S3Files
$SourceFiles | Add-Member -Name LocalKey -MemberType ScriptProperty -Value {$this.FullName.Replace($RootLocalPath, "").Replace("\","/")}

foreach ($file in $SourceFiles)
{
	$S3File = $S3Files | Where-Object {$_.Key -eq $file.LocalKey}

	if ($S3File)
	{
		if ((Get-Date $S3File.LastModified).ToUniversalTime() -gt ($file.LastWriteTimeUtc))
		{
			#Write-Host ">" $S3File.Key (Get-Date $S3File.LastModified).ToUniversalTime()
			#Write-Host "<" $file.Name $file.LastWriteTimeUtc
			Write-S3Object -BucketName $BucketName -File $file -Key $file.LocalKey -CannedACLName PublicRead
		}
	}
	else
	{
		Write-S3Object -BucketName $BucketName -File $file -Key $file.LocalKey -CannedACLName PublicRead
	}
}


#Write-S3Object [-BucketName <System.String>] [-Key <System.String>] [-File
#<System.String>] [-KeyPrefix <System.String>] [-Folder <System.String>]
#[-Recurse <System.Management.Automation.SwitchParameter?>] [-SearchPattern
#<System.String>] [-CannedACLName <System.String>] [-PublicReadOnly
#<System.Management.Automation.SwitchParameter?>] [-PublicReadWrite
#<System.Management.Automation.SwitchParameter?>] [-ContentType
#<System.String>] [-Timeout <System.Int32?>] [-StandardStorage
#<System.Management.Automation.SwitchParameter?>]
#[-ReducedRedundancyStorage
#<System.Management.Automation.SwitchParameter?>] [-ServerSideEncryption
#<System.String>] [<CommonParameters>]