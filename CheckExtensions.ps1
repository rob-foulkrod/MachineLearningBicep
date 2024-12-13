param (
    [string]$extensionName = "ml"
)

function Check-AzExtension {
    param (
        [string]$extensionName
    )

    $extensions = az extension list --output json | ConvertFrom-Json 
    $extensionInstalled = $false 
    foreach ($extension in $extensions) { 
        if ($extension.name -eq $extensionName) { 
            $extensionInstalled = $true
            break 
        } 
    } 

    return $extensionInstalled
}

function Install-AzExtension {
    param (
        [string]$extensionName
    )

    az extension add --name $extensionName
}

if (Check-AzExtension -extensionName $extensionName) {
    Write-Output "The 'az $extensionName' extension is installed. Continuing"
}
else {
    Write-Output "The 'az $extensionName' extension is not installed and is needed for this script"
    Write-Output "Install now (Y or N)?"
    $install = Read-Host
    if ($install -eq "Y") {
        Install-AzExtension -extensionName $extensionName
    }
    else {
        Write-Output "Exiting script"
        exit
    }
}

$extensionName = "ml" 
$extensions = az extension list --output json | ConvertFrom-Json 
$extensionInstalled = $false 
foreach ($extension in $extensions) { 
    if ($extension.name -eq $extensionName) { 
        $extensionInstalled = $true
        break 
    } 
} 

if ($extensionInstalled) { 
   Write-Output "The 'az $extensionName' extension is installed. Continuing"
} 
else { 
    Write-Output "The 'az $extensionName' extension is not installed and is needed for this script."
    $install = Read-Host -Prompt "Install now? (Y or N)"
    if ($install -eq "Y") {
        Install-AzExtension -extensionName $extensionName
    } else {
        Write-Output "Exiting script"
        exit
    }
}