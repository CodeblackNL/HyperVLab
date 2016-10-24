#Requires -Version 5.0

function Merge-Token {
    param (
        [PSCustomObject]$InputObject,
        [Hashtable]$Tokens,
        [Array]$Processed
    )

    function MergeToken {
        param (
            [string]$Value,
            [Hashtable]$Tokens
        )

        if ($Value -and $Value -match '\{(?<token>.*)\}') {
            foreach ($match in $Matches) {
                $Value = $Value.Replace("{$($match.token)}", $Tokens.($match.token))
            }
        }

        return $Value
    }

    if (-not $Processed) {
        $Processed = @()
    }
    elseif ($Processed.Contains($InputObject)) {
        return
    }

    $Processed += $InputObject

    foreach ($property in $InputObject.GetType().GetProperties()) {
        $value = $InputObject.($property.Name)

        if ($property.PropertyType.Name -eq 'String') {
            $InputObject.($property.Name) = MergeToken -Value $value -Tokens $Tokens
        }
        elseif ($property.PropertyType.Name -eq 'SecureString') {
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

            $newPassword = MergeToken -Value $password -Tokens $Tokens
            if ($newPassword -ne $password) {
                $InputObject.($property.Name) = ConvertTo-SecureString -String $newPassword -AsPlainText -Force            }
        }
        elseif ($value -is [System.Collections.Hashtable]) {
            foreach ($key in @($value.Keys)) {
                $value.$key = MergeToken -Value $value.$key -Tokens $Tokens
            }
        }
        elseif ($value -is [System.Collections.IEnumerable]) {
            foreach ($item in $value) {
                Merge-Token -InputObject $item -Tokens $Tokens -Processed $Processed
            }
        }
        elseif ($value -is [LabObject]) {
            #Write-Verbose "LabObject [$($property.PropertyType.Name)] $value"
            Merge-Token -InputObject $value -Tokens $Tokens -Processed $Processed
        }
    }
}
