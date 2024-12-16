function Get-BicepInstalled {
    try {
        $bicepVersion = az bicep version
        return $true
    } catch {
        return $false
    }
}

function Install-Bicep {
    az bicep install
}

# Check if Bicep is installed
$bicepInstalled = Get-BicepInstalled

if (-not $bicepInstalled) {
    Write-Output "Bicep is not installed and is needed for this script."
    $install = Read-Host -Prompt "Install now? (Y or N)"
    if ($install -eq "Y") {
        Install-Bicep
    }
    else {
        Write-Output "Exiting script"
        exit
    }
}