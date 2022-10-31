<#
 # For end user modifications.
 # See README for detailed instructions on which parameters to change.
#>

param (
    [switch]
    $Version
)

<# Defaults for "Global" cloud environment endpoints and "global" M365
$LogIn            = $true
$ProductNames     = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
$Endpoint         = "prod"
$OutPath          = "./Reports"
$OPAPath          = "./"
$CloudEnvironment = "Global"
#>

<# Defaults for "Global" cloud environment endpoints and "GCC" M365
$LogIn            = $true
$ProductNames     = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
$Endpoint         = "usgov"
$OutPath          = "./Reports"
$OPAPath          = "./"
$CloudEnvironment = "Global"
#>

<# Defaults for "Azure Government" cloud environment endpoints and "GCC High" M365
$LogIn            = $true
$ProductNames     = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
$Endpoint         = "usgovhigh"
$OutPath          = "./Reports"
$OPAPath          = "./"
$CloudEnvironment = "USGovHigh"
#>

$LogIn            = $true # Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false to avoid reauthentication
$ProductNames     = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams") # The specific products that you want the tool to assess.
$Endpoint         = "usgovhigh" # Mandatory parameter if running Power Platform. Valid options are "dod", "prod", "preview", "tip1", "tip2", "usgov", or "usgovhigh".
$OutPath          = "./Reports" # Report output directory path. Leave as-is if you want the Reports folder to be created in the same directory where the script is executed.
$OPAPath          = "./" # Path to the OPA Executable. Leave this as-is for most cases.
$CloudEnvironment = "USGovHigh" # Set the M365 Cloud Environment. Options are "Global" or "USGovHigh".

$SCuBAParams = @{
    'Login'            = $Login;
    'ProductNames'     = $ProductNames;
    'Endpoint'         = $Endpoint;
    'OPAPath'          = $OPAPath;
    'OutPath'          = $OutPath;
    'CloudEnvironment' = $CloudEnvironment;
}

$ManifestPath = Join-Path -Path "./PowerShell" -ChildPath "ScubaGear"
#######
Import-Module -Name $ManifestPath -ErrorAction Stop
if ($Version) {
    Invoke-SCuBA @SCuBAParams -Version
}
else {
    Invoke-SCuBA @SCuBAParams
}
Remove-Module "ScubaGear" -ErrorAction "SilentlyContinue"
#######
