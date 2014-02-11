<#
.Synopsis
   New OneTimeSecret
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-OneTimeSecret
{
    [CmdletBinding()]
    [OutputType([Object])]
    Param
    (
        # The secret value which is encrypted before being stored. There is a maximum length based on your plan that is enforced (1k-10k).
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $Secret,

        # A string that the recipient must know to view the secret. This value is also used to encrypt the secret and is bcrypted before being stored so we only have this value in transit.
        [Parameter(Position=1)]
        [String]
        $PassPhrase,

        # The maximum amount of time, in seconds, that the secret should survive (i.e. time-to-live). Once this time expires, the secret will be deleted and not recoverable.
        [Parameter(Position=2)]
        [Int]
        $Ttl,

        # An email address. We will send a friendly email containing the secret link (NOT the secret itself).
        [Parameter(Position=3)]
        [String]
        $Recipient
    )

    Begin
    {
        $uri = "https://onetimesecret.com/api/v1/share"
        $secpasswd = ConvertTo-SecureString 'apikey' -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ('useraccount', $secpasswd)        
    }
    Process
    {

        $secret = $_

        $body = @{secret=$secret}

        if ($PSBoundParameters["PassPhrase"])
        {
            $body.Add("passphrase", $PassPhrase)
        }

        if ($PSBoundParameters["Ttl"])
        {
            $body.Add("ttl", $Ttl)
        }

        if ($PSBoundParameters["Recipient"])
        {
            $body.Add("recipient", $Recipient)
        }

        Try {
            $results = Invoke-RestMethod -Uri $uri -Credential $cred -Method Post -Body $body -ContentType "multipart/form-data" -Verbose
               
            Write-Output -InputObject $results

            Write-Verbose "Private URL: https://onetimesecret.com/private/$($results.metadata_key)"
            Write-Verbose "Public URL: https://onetimesecret.com/secret/$($results.secret_key)"
        }
        catch
        {
            Write-Error $_
        }
    }
    End
    {
    }
}