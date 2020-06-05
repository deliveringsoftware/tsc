Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$user,
    [string]$teamProject,
    [string]$group

)

echo $PAT | az devops login --org $Organization

Write-Host '==Configuring connection to organization'
az devops configure --defaults organization=$Organization

$groupDescriptor = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].descriptor" -o tsv)
$groupDisplayName = $(az devops security group list --organization $Organization --project $teamProject --query "graphGroups[?contains(displayName, '$group')].displayName" -o tsv)

Write-Host '======Inserting' $user 'on' $groupDisplayName 'group'
az devops security group membership add --group-id $groupDescriptor --member-id $user --org $Organization
