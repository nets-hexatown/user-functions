$users = @{}

$user = @{}
$user.UserPrincipialName = "niels"
$user.ObjectId = "280363"
$user.Manager = "251238"
$users.Add($user.ObjectId, $user)
#$users += $user 

$user = @{}
$user.UserPrincipialName = "ole"
$user.ObjectId = "251238"
$user.Manager = "olefar"
$users.Add($user.ObjectId, $user)

$user = @{}
$user.UserPrincipialName = "ole"
$user.ObjectId = "olefar"
$users.Add($user.ObjectId, $user)



foreach ($u in $users) {
    Write-Output $u
}
