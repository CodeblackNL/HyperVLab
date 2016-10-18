#Requires -Version 4.0
param (
    [int]$Port = 7000
)

try {
    $endpoint = new-object System.Net.IPEndPoint ([System.Net.IPAddress]::Any, $Port)
    $receiver = new-object System.Net.Sockets.UdpClient $Port
    Write-Host "Started listening on port '$Port'"

    do {
        if ($receiver -and $receiver.Client.Poll(500, [System.Net.Sockets.SelectMode]::SelectRead)) {
            $dataBytes = $receiver.Receive([ref]$endpoint)
            $dataText = [System.Text.Encoding]::ASCII.GetString($dataBytes)
            $data = ConvertFrom-Json $dataText
            $exit = $data.exit
            if ($data.exit) {
                break
            }

            Write-Host ("{0:HH:mm:ss.fff} {1,-10} ({2}): {3} " -f $data.timestamp, $data.hostname,$data.instanceId,$data.message) -fore cyan
        }
        else {
            Start-Sleep -Milliseconds 500
        }
    } while ($true)
}
catch {
    Write-Error $_
}
finally {
    if ($receiver) {
        $receiver.Close()
    }
}
