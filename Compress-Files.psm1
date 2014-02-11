<#
	.SYNOPSIS
	Simple wrapper for 7-Zip
	
	.DESCRIPTION
	Compresses a Path with ZIP compression.
	
	.PARAMETER Source
	File path to compress.
	
	.PARAMETER Destination
	Name and location of the archive to be produced.
	
	.PARAMETER ZipExePath
	Path to the 7-zip binary.  Default is "C:\Program Files\7-Zip\7z.exe".

	.EXAMPLE
	Compress-Files c:\temp "C:\temp\archive(Get-Date -f yyyyMMdd).zip"
	
	.OUTPUTS
	None.
	
#>
function Compress-Files (
  [string]$Source = $(throw "Missing: parameter Source"), 
  [string]$Destination = $(throw "Missing: parameter Destination"), 
  [string]$ZipExePath = "C:\Program Files\7-Zip\7z.exe"
) {
		
	$archiveName = & $zipExePath a -tzip -y $destination $source
}

Export-ModuleMember -Function Compress-Files