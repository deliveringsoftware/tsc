Param
(    
    [Parameter(Mandatory=$true)]     
    [SecureString]$PAT,      
    [string]$file = ".\SecurityTree.yml"
)

# TODO Validar se o modulo esta inslado
Import-Module powershell-yaml

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$here\AzDO-Functions.ps1"
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

    return (az devops project list --query "value[?name == '$TeamProjectName'].id")
}

function Get-MembersFromGroup {
    param (
        [string]$organization,
        [string]$teamProject,
        [string]$group,
        [ValidateSet("user","group")]
        [string]$kind = "user"
    )

    $userGroup = Get-UserGroup -Organization $organization -teamProject $teamProject -group $group

    $groupMembers = $(az devops security group membership list --id $userGroup.Descriptor --relationship members --query "*.{name: displayName, principalName: principalName, kind: subjectKind}" -o json) | ConvertFrom-Json

    return $groupMembers | Where { $_.kind -eq $kind }
}

function Get-UserGroup {
    param (
        [string]$organization,        
        [string]$teamProject,
        [string]$group
    )

    $groupDescriptor = $(az devops security group list --organization $Organization `
                            --project $teamProject `
                            --query "graphGroups[?contains(displayName, '$group')].descriptor" -o tsv)
    $groupDisplayName = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].displayName" -o tsv)

    if(-not ($groupDescriptor)){
        Write-Error "User Group no found"
    }

    return New-Object PSObject -Property @{
        Descriptor       = $groupDescriptor
        DisplayName     = $groupDisplayName
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
Write-Output (Get-PersonalAccessToken $PAT) | az devops login --org $OrganizationUrl

Write-Host '=== Configuring connection to organization ==='
az devops configure --defaults organization=$OrganizationUrl

$teamProjects = Get-TeamProjects 

foreach ($teamProject in $teamProjects){
    $TeamProjectId = Confirm-TeamProject -TeamProjectName $teamProject.name

    if ($TeamProjectId) {
        Write-host "=== TeamProject '$($teamProject.name)' existe ==="
        $ymlGroups = $teamProject.groups
        foreach ($ymlGroup in $ymlGroups) {
            $ymlUsers = $ymlGroup.users
            
            Add-UsersToGroup -PAT $PAT -Organization $OrganizationUrl -users $ymlUsers -teamProject $teamProject.name -group $ymlGroup.name
        }        

    } else {
        Write-Host "=== O Team Project '$($teamProject.name)' não existe"
    }
}