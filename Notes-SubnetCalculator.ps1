<#
$ip = [IPAddress]"192.168.1.2"
$bits = 26

$mask = -bNot ([uint32]::MaxValue -shR $bits)

$maskBytes = [BitConverter]::GetBytes($mask)
[Array]::Reverse($maskBytes)

$ipBytes = $ip.GetAddressBytes()

$startIPBytes = New-Object byte[] $ipBytes.Length
$endIPBytes = New-Object byte[] $ipBytes.Length

for ($i = 0; $i -lt $ipBytes.Length; $i++)
{
    $startIPBytes[$i] = $ipBytes[$i] -bAnd $maskBytes[$i]
    
    $octet = -bNot [byte]$maskBytes[$i]
    $octetBytes = [BitConverter]::GetBytes($octet)[0]
    $endIPBytes[$i] = $ipBytes[$i] -bOr $octetBytes
}

$startIP = [IPAddress]$startIPBytes
$endIP = [IPAddress]$endIPBytes

$startIP
$endIP
#>

function Increment ([IPAddress]$address)
{
    $bytes = $address.GetAddressBytes()

    for($k = $bytes.Length - 1; $k -ge 0; $k--)
    {
        $value = [BitConverter]::GetBytes($bytes[$k])[0]

        if( $value -eq ([byte]::MaxValue) )
        {
            $bytes[$k] = 0
            continue
        }

        $bytes[$k]++

        return [IPAddress]$bytes
    }
}

$nextIp = $startIP
$nextIP = Increment $nextIp

While ($nextIp -ne $endIP)
{
    Write-Output $nextIp
    $nextIP = Increment $nextIp    
}
