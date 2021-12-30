#region Config
$Config = $Configuration | ConvertFrom-Json

# - Add your configuration variables here -
$Uri = $Config.Uri
#endregion Config

#region default properties
$p = $Person | ConvertFrom-Json
$m = $Manager | ConvertFrom-Json

$aRef = New-Guid
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
function Get-ExampleFunction
{
    param(
        [Parameter(Mandatory)]
        [string]
        $ParameterName
    )

    return $Example
}
#endregion functions

# Build the Final Account object
$Account = @{
    DisplayName = $p.DisplayName
    FirstName   = $p.Name.NickName
    LastName    = $p.Name.FamilyName
    UserName    = $p.UserName
    ExternalId  = $aRef
    Title       = $p.PrimaryContract.Title.Name
    Department  = $p.PrimaryContract.Department.DisplayName
    StartDate   = $p.PrimaryContract.StartDate
    EndDate     = $p.PrimaryContract.EndDate
    Manager     = $p.PrimaryManager.DisplayName
}

$Success = $False

# Start Script
try {
    # Place the entire logic in a Try/Catch, this will make sure the script always finishes and can return the error to HelloID
    # perform as much of the logic before the dry-run check, so this is validatable with a dry run.
    # This way, Errors can be thrown in the script to stop it.

    if (-Not ($dryRun -eq $True)) {
        # Write create logic here
        $Body = $Account | ConvertTo-Json -Depth 10 -Compress

        [void] (Invoke-RestMethod -Method 'Post' -Uri $Uri -Body $Body)
    }
    else {
        # For the dryrun, we can dump the request body in the verbose logging
        Write-Verbose -Verbose (
            $Account | ConvertTo-Json -Depth 10
        )
    }

    $AuditLogs.Add([PSCustomObject]@{
        Action  = "CreateAccount" # Optionally specify a different action for this audit log
        Message = "Correlated to and updated fields of account with id $($aRef)"
        IsError = $False
    })

    # if we reached the end of the Try, we can asume the script has done its job succesfully
    $Success = $True
}
catch {
    $AuditLogs.Add([PSCustomObject]@{
        Action  = "CreateAccount" # Optionally specify a different action for this audit log
        Message = "Error creating account with ID $($aRef): $($_)"
        IsError = $True
    })

    Write-Warning $_
}

# Send results
$Result = [PSCustomObject]@{
    Success          = $Success
    AccountReference = $aRef
    AuditLogs        = $AuditLogs
    Account          = $Account

    # Optionally return data for use in other systems
    ExportData = [PSCustomObject]@{
        DisplayName = $Account.DisplayName
        UserName    = $Account.UserName
        ExternalId  = $aRef
    }
}

Write-Output $Result | ConvertTo-Json -Depth 10
