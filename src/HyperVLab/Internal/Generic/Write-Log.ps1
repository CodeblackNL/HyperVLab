
function Write-Log {
    param (
        $Date = (Get-Date),
        $Scope, 
        $Message
    )

    Write-Verbose -Message "$Date [$($Scope.MyCommand)] :: $Message"
}