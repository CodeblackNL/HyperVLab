
function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory)]
		[String]$Message,

		[parameter(Mandatory = $false)]
		[String]$Port = 7000
	)

    @{
		Message = $Message
		Port = $Port
	}
}

function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory)]
		[String]$Message,

		[parameter(Mandatory = $false)]
		[String]$Port = 7000
	)

    return $false
}

function Set-TargetResource {
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory)]
		[String]$Message,

		[parameter(Mandatory = $false)]
		[String]$Port = 7000
	)

    Write-Verbose "Sending message '$Message' to $Port"

    try {
        $data = @{
            timestamp = [DateTime]::Now
            hostname = $env:COMPUTERNAME
            instanceId = $host.InstanceId
            message = $Message
        }

        $dataText = $data | ConvertTo-Json
        $dataBytes = [System.Text.Encoding]::ASCII.GetBytes($dataText)

        $address = [System.Net.IPAddress]::Broadcast
        $endpoint = new-object System.Net.IPEndPoint ($address, $Port)
        $client = New-Object Net.Sockets.UdpClient

        $bytesSent = $client.Send($dataBytes, $dataBytes.Length, $endpoint)
        Write-Verbose "$bytesSent bytes sent"

        Start-Sleep -Milliseconds 100
    }
    catch {
    }
    finally {
        if ($client) {
            $client.Close()
        }
    }
}

Export-ModuleMember -Function *-TargetResource
