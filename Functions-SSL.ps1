<#
.Synopsis
   Generates a new certificate signing request (CSR)
.DESCRIPTION
   Will generate a certificate signing request (CSR) using OpenSSL.  
.EXAMPLE
   New-CertificateSigningRequest -CommonName blah.com, meh.org
   
   Basic usage of the cmdlet.  It will generate a CSR for both blah.com and meh.org.  
.EXAMPLE
   New-CertificateSigningRequest -CommonName blah.com, meh.org -Organization "Redmond" -State "California" -CountryCode "US"

   The cmdlet is now utilizing parameters to specify a different organization, state, and country code to be utilized in the CSR
.Parameter
    CommonName
        The fully qualified domain name (FQDN) of your server. This must match exactly what you type in your web browser or you will receive a name mismatch error. 
.Parameter
    Organization
        The legal name of your organization. This should not be abbreviated and should include suffixes such as Inc, Corp, or LLC.
.Parameter
    OrganizationalUnit
        The division of your organization handling the certificate.
.Parameter
    Locality/City
        The city where your organization is located.
.Parameter
    State/County/Region
        The state/region where your organization is located. This shouldn't be abbreviated.
.Parameter
    CountryCode
        The two-letter ISO code for the country where your organization is location.
.OUTPUTS
   Standard output from OpenSSL will be shown, which contains the common name, and where the csr and key are being written to.
#>

function New-CertificateSigningRequest 
{
	
	Param( 
		
		[Parameter(Mandatory=$true,ValueFromPipeLine=$true)] [alias("CN")] [string[]]$CommonName,
		[alias("O")] [string]$Organization = "Organization",
		[alias("OU")] [string]$OrganizationalUnit = "OrganizationalUnit",
		[alias("ST")] [string]$State = "State",
		[alias("L")] [string]$Locality = "Locality",
		[alias("C")] [string]$CountryCode = "CountryCode"
	
	)
	   
	$dir = "\\server\SSL"
	$pass = "password"
	$config = "c:\OpenSSL-Win64\openssl.cfg"

	#Loop through each hostname given in CommonName parameter, and create a separate cert / key pair for each.
	foreach ($site in $CommonName) {

		$site = $site.ToLower()
		$fileName = $site
		Write-Host
		Write-Host "Generating Request for $site" -ForegroundColor Yellow
	
		if ($site.StartsWith("*")) {
     		$fileName = $site.Replace("*", "wildcard")
    	}
	
		#Invoke OpenSSL command to generate new cert and key pair for each site.
		& $ssl req -new -newkey rsa:2048 -passin pass:$pass -subj "/CN=$site/O=$organization/OU=$OrganizationalUnit/ST=$State/L=$Locality/C=$CountryCode" `
		-nodes -keyout (Join-Path "$dir" "$fileName.key") -out (Join-Path "$dir" "TXT\$fileName.txt") -config $config

	}
}


<#
.Synopsis
   Comnbines signed certificates with associated private key.
.DESCRIPTION
   Utilizing OpenSSL, this cmdlet will take all all certificate files greater than 0KB, and combine them with the private key, to form a PKCS#12 (PFX) file.
   No parameters need to be passed for this cmdlet to function, other than a valid, signed certificate file to be present in the SSL directory. 
.EXAMPLE
   Install-Certificate
   
   Basic usage of the cmdlet.  It will find any non-empty certificate files, and combine them with the private key to form a PKCS#12 (PFX) file.  
.EXAMPLE
  Install-Certificate -zip

  The zip Parameter will call New-CertZip and add all generated PFX files to a zip archive, and then place them on your desktop.
.Example
   New-CertificateSigningRequest -CommonName blah.com, meh.org
.Parameter
    zip
        This switch will call the New-CertZip function, and all all processed certificates to a zip archive.
.OUTPUTS
   Output will show write the certificate name, and the standard output for OpenSSL
.NOTES
    This function calls the Rename-Extensions function.  It is a known bug that this will error in some cases, but functionality is not hindered.
#>

function Install-Certificate 
{    

    Param(
		[switch]$zip,
		[switch]$VIPList
	)
	$pass = "password"
	$dir = "\\server\SSL"
	$date = Get-Date -Format yyyyMM-
	$nameArray = @()
	$files = Get-ChildItem $dir

	Rename-Extensions

	#Build list of certificates to convert to .pfx's
	$siteList = (Get-ChildItem "$dir" -Filter "*.crt" | where { $_.Length -gt 0 } )

	#Loop through and convert the certificates to .pfx's
	foreach ($site in $siteList){ 

		$name = $site.BaseName
		$nameArray += $name

		Write-Host $name -ForegroundColor Yellow
		
		if ( (Test-CertKeyMatch -certPath (Join-Path "$dir" "$name.crt") -keyPath (Join-Path "$dir" "$name.key")) -eq $true ) {
  
			$output = & $ssl pkcs12 -export -passout pass:$pass -out (Join-Path "$dir" "$name.pfx")`
			-inkey (Join-Path "$dir" "$name.key") -in (Join-Path "$dir" "$name.crt")

			Write-Host
			Write-Host
		
			Move-Item -LiteralPath "$dir\$name.pfx" -Destination (Join-Path "$dir" "PFX\$name.pfx")
			Move-Item -LiteralPath "$dir\$name.crt" -Destination (Join-Path "$dir" "Processed\$name.crt")
			Move-Item -LiteralPath "$dir\$name.key" -Destination (Join-Path "$dir" "Processed\$name.key")
          

		}
		
		else {
		
			Write-Host -ForegroundColor Red "Not processing certificate: Certificate and Key do not match"
		
		}
	}
	
	if ($zip -eq $true) {
	
		New-CertZip -CN $nameArray
		
    }

}

function Rename-Extensions 
{
     $dir = "\\server\SSL"
     
	#Convert any non-empty .txt's to .crt's
	#get-childItem $dir | where {$_.LastWriteTime -gt (Get-Date -Format MM-dd-yyyy) -and $_.length -gt 0} `
	#| rename-item -newname { $_.name -replace '\.txt','.crt' }
	
	Get-ChildItem $dir -Exclude "*.csv","*.txt" | where {$_.name.StartsWith("__")} |  Rename-Item -Path $_ -NewName {$_.name.Replace("__", "wildcard.") } 
	Get-ChildItem $dir -Exclude "*.csv","*.txt" | where {$_.length -gt 0 -and $_.Extension} | Rename-item -Path $_ -newname { $_.name -replace '_', '.'}
	Get-ChildItem $dir -Exclude "*.csv","*.txt" | where {$_.length -gt 0} | Rename-Item -Path $_ -NewName { $_.name -replace ".cert.cer", ".crt" }

	
}