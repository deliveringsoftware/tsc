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