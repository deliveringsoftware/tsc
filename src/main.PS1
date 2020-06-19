Param
(
    [string]$PAT,
    [string]$Organization,
    [string[]]$users,
    [string]$teamProject,
    [string]$group

)
Write-Host "=== Loggin to organization $Organization ===" #TODO: Write only the name of organization
echo $PAT | az devops login --org $Organization

Write-Host '=== Configuring connection to organization ==='
az devops configure --defaults organization=$Organization

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
        Write-Host "=== Inserting user $user ==="
        az devops security group membership add --group-id $groupDescriptor --member-id $user --org $Organization
    }
}

Add-UsersToGroup -PAT $PAT -Organization $Organization -users $users -teamProject $teamProject -group $group