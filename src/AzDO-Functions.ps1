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

function Remove-UsersToGroup {
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

    Write-Host "=== Removing users on $groupDisplayName group ==="

    foreach ($user in $users) {
        Write-Host ("=== Removing user {0} ===" -f $user.name)
        az devops security group membership remove --group-id $groupDescriptor --member-id $user.email --org $Organization -y | Out-Null
    }
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