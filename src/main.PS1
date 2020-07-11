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

function Add-UsersToGroup {
    param (
        [string]$Organization,
        [System.Collections.ArrayList]$users,
        [string]$teamProject,
        [string]$group
    )

    $groupDescriptor = $(az devops security group list --organization $Organization `
                            --project $teamProject `
                            --query "graphGroups[?contains(displayName, '$group')].descriptor" -o tsv)
    $groupDisplayName = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].displayName" -o tsv)

    Write-Host "=== Inserting users on $groupDisplayName group ==="

    foreach ($user in $users) {
        Write-Host ("=== Inserting user {0} ===" -f $user.name)
        az devops security group membership add --group-id $groupDescriptor --member-id $user.email --org $Organization | Out-Null
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
        $groups = $teamProject.groups
        foreach ($group in $groups) {
            $users = $group.users

            #$groupUsers = Get-MembersFromGroup -organization $OrganizationUrl -teamProject $teamProject.name -group $group.name
            
            Add-UsersToGroup -PAT $PAT -Organization $OrganizationUrl -users $users -teamProject $teamProject.name -group $group.name
        }        

    } else {
        Write-Host "=== O Team Project '$($teamProject.name)' não existe"
    }
}