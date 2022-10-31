function Connect-Tenant {
     <#
    .Description
    This function uses the various PowerShell modules to establish
    a connection to an M365 Tenant associated with provided
    credentials
    .Functionality
    Internal
    #>
    param (
    [Parameter(Mandatory=$true)]
    [string[]]
    $ProductNames,

    [string]
    $Endpoint,

    #Set the M365 Cloud Environment
    [ValidateSet("Global", "USGov")]
    [string]
    $Environment="Global"
    )

    # Prevent duplicate sign ins
    $EXOAuthRequired = $true
    $SPOAuthRequired = $true
    $AADAuthRequired = $true

    $N = 0
    $Len = $ProductNames.Length

    foreach ($Product in $ProductNames) {
        $N += 1
        $Percent = $N*100/$Len
        Write-Progress -Activity "Authenticating to each service" -Status "Authenticating to $($Product); $($n) of $($Len) Products authenticated to." -PercentComplete $Percent
        switch ($Product) {
            {($_ -eq "exo") -or ($_ -eq "defender")} {
                if ($EXOAuthRequired) {
                    switch ($Environment) {
                        USGov {
                            Connect-ExchangeOnline -ShowBanner:$false -ExchangeEnvironmentName O365USGovGCCHigh | Out-Null
                        }
                        Global {
                            Connect-ExchangeOnline -ShowBanner:$false | Out-Null
                         }
                        Default {
                            Write-Error "'$Environment' has no connector for $Product."
                        }
                    }
                    Write-Verbose "Defender will require a sign in every single run regardless of what the LogIn parameter is set"
                    $EXOAuthRequired = $false
                }
            }
            "aad" {
                $scopes = (
                    'User.Read.All',
                    'Policy.Read.All',
                    'Directory.Read.All',
                    'GroupMember.Read.All',
                    'Organization.Read.All',
                    'RoleManagement.Read.Directory',
                    'UserAuthenticationMethod.Read.All',
                    'Policy.ReadWrite.AuthenticationMethod'
                )
                switch ($Environment) {
                    USGov {
                        Connect-MgGraph -Environment UsGov -Scopes $scopes -ErrorAction Stop | Out-Null
                    }
                    Global {
                        Connect-MgGraph -Scopes $scopes -ErrorAction Stop | Out-Null
                     }
                    Default {
                        Write-Error "'$Environment' has no connector for $Product."
                    }
                }
                Select-MgProfile Beta | Out-Null
                $AADAuthRequired = $false
            }
            "powerplatform"{
                if (!$Endpoint) {
                    Write-Output "Power Platform needs an endpoint please specify one as a script arg"
                }
                else {
                    switch ($Environment) {
                        USGov {
                            Add-PowerAppsAccount -Endpoint $Endpoint -Endpoint "usgov"  | Out-Null
                        }
                        Global {
                            Add-PowerAppsAccount -Endpoint $Endpoint | Out-Null
                         }
                        Default {
                            Write-Error "'$Environment' has no connector for $Product."
                        }
                    }
                }
            }
            {($_ -eq "onedrive") -or ($_ -eq "sharepoint")} {
                if ($AADAuthRequired) {
                    switch ($Environment) {
                        USGov {
                            Connect-MgGraph  -Environment UsGov | Out-Null
                        }
                        Global {
                            Connect-MgGraph | Out-Null
                        }
                        Default {
                            Write-Error "'$Environment' has no connector for $Product."
                        }
                    }
                    Select-MgProfile Beta | Out-Null
                    $AADAuthRequired = $false
                }
                if ($SPOAuthRequired) {
                    $InitialDomain = (Get-MgOrganization).VerifiedDomains | Where-Object {$_.isInitial}
                    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]
                    switch ($Environment) {
                        USGov {
                            Connect-SPOService -Url "https://$($InitialDomainPrefix)-admin.sharepoint.us" -Region ITAR | Out-Null
                        }
                        Global {
                            Connect-SPOService -Url "https://$($InitialDomainPrefix)-admin.sharepoint.com" | Out-Null
                         }
                        Default {
                            Write-Error "'$Environment' has no connector for $Product."
                        }
                    }
                    $SPOAuthRequired = $false
                }
            }
            "teams" {
                switch ($Environment) {
                    USGov {
                        Connect-MicrosoftTeams -TeamsEnvironmentName TeamsGCCH | Out-Null
                    }
                    Global {
                        Connect-MicrosoftTeams | Out-Null
                     }
                    Default {
                        Write-Error "'$Environment' has no connector for $Product."
                    }
                }
            }
            default {
                Write-Error -Message "Invalid ProductName argument"
            }
        }
    }
    Write-Progress -Activity "Authenticating to each service" -Status "Ready" -Completed
}

function Disconnect-Tenant {
    <#
    .Description
    This function disconnects the various PowerShell module sessions from the
    M365 Tenant. Useful to disconnect then connect to other M365 tenants
    Currently Disconect-MgGraph is buggy and may not disconnect properly.
    .Functionality
    Public
    #>
    Disconnect-MicrosoftTeams # Teams
    Disconnect-MgGraph # AAD
    Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue | Out-Null # Exchange and Defender
    Remove-PowerAppsAccount # Power Platform
    Disconnect-SPOService # OneDrive and Sharepoint
}

Export-ModuleMember -Function @(
    'Connect-Tenant',
    'Disconnect-Tenant'
)
