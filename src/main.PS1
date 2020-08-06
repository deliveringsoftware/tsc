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

            $tpUsers = Get-MembersFromGroup -organizationUrl $OrganizationUrl -teamProject $teamProject.name -group $ymlGroup.name

            $usersToAdd = [System.Collections.ArrayList]@()

            foreach ($ymlUser in $ymlUsers) {
                $userExist = $false
                foreach ($tpUser in $tpUsers) {
                    if ($ymlUser.email -eq $tpUser.principalName) {
                        $userExist = $true
                    }
                }

                if ($userExist){
                    Write-host "=== User '$($ymlUser.name)' EXISTS on group '$($ymlGroup.name)' ==="
                }
                else {
                    $usersToAdd.Add($ymlUser)
                }
            }

            if ($usersToAdd.Count -gt 0) {
                Add-UsersToGroup -PAT $PAT -Organization $OrganizationUrl -users $usersToAdd -teamProject $teamProject.name -group $ymlGroup.name
            }

            # == Remove users == #
            $usersToRemove = [System.Collections.ArrayList]@()
            foreach ($tpUser in $tpUsers) {
                $userExist = $false
                foreach ($ymlUser in $ymlUsers) {
                    if ($tpUser.principalName -eq $ymlUser.email) {
                        $userExist = $true
                    }
                }

                if ($userExist){
                    # Write-host "=== User '$($ymlUser.name)' EXISTS on group '$($ymlGroup.name)' ==="
                }
                else {
                    $user = @{name=$tpUser.name;email=$tpUser.principalName}
                    $usersToRemove.Add($user)
                }
            }

            if ($usersToRemove.Count -gt 0) {
                Remove-UsersToGroup -PAT $PAT -Organization $OrganizationUrl -users $usersToRemove -teamProject $teamProject.name -group $ymlGroup.name
            }
        }
    } else {
        Write-Host "=== O Team Project '$($teamProject.name)' não existe"
    }
}