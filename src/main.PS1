Param
(    
    [Parameter(Mandatory=$true)]     
    [SecureString]$PAT,      
    [string]$file = ".\SecurityTree.yml"
)

Import-Module powershell-yaml

function Get-PersonalAccessToken{
    param(
        [SecureString]$secureString
    )
    $secstring = ConvertTo-SecureString -string (ConvertFrom-SecureString $secureString)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstring)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

function Confirm-TeamProject {
    param (
        [string]$TeamProjectName
    )

    return (az devops project list --query "value[?name == '$TeamProjectName'].id") | ConvertFrom-Json
}

function Add-UsersToGroup {
    param (
        [string]$Organization,
        [string[]]$users,
        [string]$teamProject,
        [string]$group
    )

    $groupDescriptor = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].descriptor" -o tsv)
    $groupDisplayName = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].displayName" -o tsv)

    Write-Host "=== Inserting users on $groupDisplayName group ==="

    foreach ($user in $users) {
        Write-Host ("=== Inserting user {0} ===" -f $user)
        az devops security group membership add --group-id $groupDescriptor --member-id $user --org $Organization | Out-Null
    }
}

function Get-AzDOStructure{
    $yamlFile = Get-Content $file -Raw

    $AzDOStructure = ConvertFrom-Yaml $yamlFile
    return $AzDOStructure
}

function Get-Organization{
    $AzDOStructure = Get-AzDOStructure

    return $AzDOStructure.Org.Name
}

function Get-OrganizationURL{
    return "https://dev.azure.com/$(Get-Organization)"
}

function Get-TeamProjects{
    return (Get-AzDOStructure).Org.Projects
}

$Organization = Get-Organization
$OrganizationUrl = Get-OrganizationURL

Write-Host "=== Loggin to organization $Organization ===" #TODO: Write only the name of organization

# $PATSec = Get-PersonalAccessToken
echo (Get-PersonalAccessToken $PAT) | az devops login --org $OrganizationUrl

Write-Host '=== Configuring connection to organization ==='
az devops configure --defaults organization=$OrganizationUrl

$teamProjects = Get-TeamProjects 

foreach ($teamProject in $teamProjects){
    $TeamProjectId = Confirm-TeamProject -TeamProjectName $teamProject.Name

    if ($TeamProjectId) {
        Write-host "=== TeamProject '$($teamProject.Name)' existe ==="
        #Add-UsersToGroup -PAT $PAT -Organization $OrganizationUrl -users $users -teamProject $teamProject -group $group
    } else {
        Write-Host "=== O Team Project '$($teamProject.Name)' não existe"
    }
}