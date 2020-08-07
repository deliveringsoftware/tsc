$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$hereUp = Split-Path -Parent $here

$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$hereUp\src\$sut"

Describe -Tags "AzureDevOps" "Add-UsersToGroup" {

    It "add user to group" {
        az devops configure --defaults organization="https://dev.azure.com/deliveringsoftware"

        $users = [System.Collections.ArrayList]@()
        $user = @{name="wescamargo";email="wescamargo@outlook.com"}
        $users.Add($user)

        Add-UsersToGroup `
            -Organization "deliveringsoftware" `
            -users $users  `
            -teamProject "sandbox" `
            -group "Contributors" `
            | Should -BeNullOrEmpty
    }
}