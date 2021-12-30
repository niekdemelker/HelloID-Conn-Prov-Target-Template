#region Config
$Config = $Configuration | ConvertFrom-Json

# - Add your configuration variables here -
$Uri = $Config.Uri
#endregion Config

#region default properties
$p = $person | ConvertFrom-Json
$m = $manager | ConvertFrom-Json

$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json

$AuditLogs = [Collections.Generic.List[PSCustomObject]]::new()
#endregion default properties

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = @(
    [Net.SecurityProtocolType]::Tls
    [Net.SecurityProtocolType]::Tls11
    [Net.SecurityProtocolType]::Tls12
)

#region functions - Write functions logic here
function Get-ExampleFunction {
    param(
        [Parameter(Mandatory)]
        [string]
        $ParameterName
    )

    return $Example
}
#endregion functions

$Success = $False

# Strart Script
try {
    # Place the entire logic in a Try/Catch, this will make sure the script always finishes and can return the error to HelloID
    # perform as much of the logic before the dry-run check, so this is validatable with a dry run.
    # This way, Errors can be thrown in the script to stop it.

    if (-Not ($dryRun -eq $True)) {
        # Write create logic here
        [void] (Invoke-RestMethod -Method 'Post' -Uri $Uri -Body $Body)

    }
    else {
        # For the dryrun, we can dump the request body in the verbose logging
        Write-Verbose -Verbose (
            $Account | ConvertTo-Json -Depth 10
        )
    }

    Write-Verbose -Verbose "Enabled account"

    $AuditLogs.Add([PSCustomObject]@{
        Action  = "EnableAccount"
        Message = "Enabled account with Id $($aRef)"
        IsError = $False
    })

    # if we reached the end of the Try, we can asume the script has done its job succesfully
    $Success = $True
}
catch {
    $AuditLogs.Add([PSCustomObject]@{
        Action  = "EnableAccount"
        Message = "Error enabling account with Id $($aRef): $($_)"
        IsError = $True
    })
    Write-Warning $_
}

# Send results
$Result = [PSCustomObject]@{
    Success   = $Success
    AuditLogs = $AuditLogs
    Account   = $Account
}

Write-Output $Result | ConvertTo-Json -Depth 10
