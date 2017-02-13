#Requires -Version 5.0

function Convert-PSObjectToHashtable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Don''t use ShouldProcess in internal functions.')]
    param (
        [Parameter(  
             Position = 0,   
             ValueFromPipeline = $true,  
             ValueFromPipelineByPropertyName = $true  
         )]
        [object]$InputObject
    )

    if (-not $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $output = @(
            foreach ($item in $InputObject) {
                Convert-PSObjectToHashtable $item
            }
        )

        Write-Output -NoEnumerate $output
    }
    elseif ($InputObject -is [psobject]) {
        $output = @{}
        $InputObject | Get-Member -MemberType *Property | ForEach-Object { 
            $output.($_.name) = Convert-PSObjectToHashtable $InputObject.($_.name)
        } 
        $output
    }
    else {
        $InputObject
    }
}
