Param ([string]$UID, [bool]$renewal = $false)
Set-PSdebug -strict

#$CerName = Join-Path -Path "\\server\CSRs" -ChildPath "$($UID)_$(Get-Date -Format yyyy-MM).cer"
#$PfxName = Join-Path -Path "d:\Certs\PFX" -ChildPath "$($cn)_$(Get-Date -Format yyyy-MM).pfx"

$UID = $UID.ToLower()

###################################
# Generate Request File
###################################
Write-Host
Write-Host "Generating Request File" -ForegroundColor Yellow

Remove-Item .\certreq.inf -ErrorAction SilentlyContinue
Remove-Item "\\server\CSRs\$UID.txt" -ErrorAction SilentlyContinue

Add-Content .\certreq.inf "[NewRequest]
Subject=`"CN=$UID,O=org,OU=orgunit,S=state,L=locality,C=country`"
KeyLength=2048
Exportable = TRUE"

If ($renewal) {
	$cert = Dir -Path "cert:\CurrentUser\my" | Where-Object {$_.subject -match "CN=$UID" -and (Get-Date $_.GetExpirationDateString()) -lt ((Get-Date).adddays(90))}
	Add-Content .\certreq.inf "RenewalCert=$($cert.thumbprint)"
}

certreq -new -machine .\certreq.inf "\\server\CSRs\$UID.txt"

Invoke-Item "\\server\CSRs\$UID.txt"


###################################
# Prep empty txt file for approved Cert
###################################
New-Item -Path "\\server\ApprovedCerts\" -Name "$UID.txt" -ItemType "file"

###################################
# Send Request  
###################################
#write-host "Sending Certificate Request" -ForegroundColor Yellow
#
#Offline cert submit
#.\certreq -submit -config "$CAName" .\supusercert.req .\$UID.cer
#
###################################
# Install Certificate
###################################
#write-host "Installing Certificate" -ForegroundColor Yellow
#
#.\certreq -accept "\\server\ApprovedCerts\$UID.cer"