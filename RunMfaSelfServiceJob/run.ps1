# Input bindings are passed in via param block.
param($Timer)

function GetCurrentTimeFromUtcLocalized {

    $currentTime = [System.DateTime]::Now.ToUniversalTime()
    $timezoneInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById($env:LocalTimeZone)

    $daylightTimeAdjustmentRule = $timezoneInfo.GetAdjustmentRules() | Where-Object { ($currentTime -gt $PSItem.DateStart) -and ($currentTime -lt $PSItem.DateEnd) }
    $daylightTimeOffset = $daylightTimeAdjustmentRule.DaylightDelta
            
    $currentTimeLocalized = $null
    $timezoneOffset = $null
    switch ($timezoneInfo.IsDaylightSavingTime($currentTime)) {
        $true {
            $timezoneOffset = $timezoneInfo.BaseUtcOffset.Add($daylightTimeOffset)
            break
        }

        Default {
            $timezoneOffset = $timezoneInfo.BaseUtcOffset
            break
        }
    }

    $currentTimeLocalized = [System.DateTimeOffset]::UtcNow.ToOffset($timezoneOffset).LocalDateTime

    return $currentTimeLocalized
}

$startTime = GetCurrentTimeFromUtcLocalized
Write-Information -Tags "BaseFunctionLog" -MessageData "Function is starting at: $($startTime.ToString("yyyy-MM-dd HH:mm:ss zzz"))"

if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

Write-Output "- Getting licensed users"
$licensedUsers = Get-AadUsersWithLicense -UserDomainName $env:UserDomainName

$usersNotEnabledWithAadIdp = Compare-AadUsersWithCorrectPolicies -GroupId $env:AadIdpEnabledGroupId -UserObjects $licensedUsers

Write-Output "- Getting MFA methods"
$usersNotEnabledWithAadIdpMfaMethods = Get-AadUserMfaMethods -UserObj $usersNotEnabledWithAadIdp -ThrottleBufferSeconds 5 -Verbose

$usersWhoSelfRegistered = $usersNotEnabledWithAadIdpMfaMethods | Where-Object { $PSItem.UsableSignInMethodCount -ne 0 }

$usersInGroupAlready = Get-MgGroupTransitiveMember -GroupId $env:AadIdpEnabledGroupId -All

Write-Output "- Processing users"
foreach ($user in $usersWhoSelfRegistered) {
    Write-Output "`t- Adding $($user.UserPrincipalName)"

    switch ($null -eq ($usersInGroupAlready | Where-Object { $PSItem.Id -eq $user.UserId })) {
        $false {
            Write-Warning "`t`t- User is already in the group."
            break
        }

        Default {
            New-MgGroupMember -GroupId $env:MfaSelfRegisteredGroupId -DirectoryObjectId $user.UserId
            break
        }
    }
}

$endTime = GetCurrentTimeFromUtcLocalized
Write-Information -Tags "BaseFunctionLog" -MessageData "Function completed at: $($endTime.ToString("yyyy-MM-dd HH:mm:ss zzz"))"

$totalTimeRan = New-TimeSpan -Start $startTime -End $endTime
Write-Information -Tags "BaseFunctionLog" -MessageData "Total time ran: $($totalTimeRan.ToString())"