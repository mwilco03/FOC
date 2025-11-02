function Show-BoundParameters {
    param(
        [string]$Name,
        [int]$Age,
        [string]$City,
        [string]$Location
    )

    Write-Host "Inside function Show-BoundParameters"
    Write-Host "`n--- PSBoundParameters Content ---"
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        Write-Host "$($_.Key) = $($_.Value)"
    }

    Write-Host "`n--- Example of Using switch with PSBoundParameters ---"

    switch -Wildcard ($PSBoundParameters.Keys) {
        "Name"      { Write-Host "Hello, $Name!" }
        "Age"       { Write-Host "You are $Age years old." }
        "City"      { Write-Host "You live in $City." }
        "Location"  { Write-Host "Your current location is $Location." }
        default     { Write-Host "No recognized parameters were passed." }
    }
}

