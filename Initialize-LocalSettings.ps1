[CmdletBinding(SupportsShouldProcess)]
param(

)

$scriptRoot = $PSScriptRoot

$localSettingOutPath = Join-Path -Path $scriptRoot -ChildPath "local.settings.json"

$localSettings = @{
    "IsEncrypted" = $true;
    "Values"      = @{
        "AzureWebJobsStorage"              = "";
        "FUNCTIONS_WORKER_RUNTIME_VERSION" = "~7";
        "FUNCTIONS_WORKER_RUNTIME"         = "powershell";
        "AadAppId"                         = "";
        "AadTenantId"                      = "";
        "AppCertThumbprint"                = "";
        "AadIdpEnabledGroupId"             = "";
        "MfaSelfRegisteredGroupId"         = "";
        "UserDomainName"                   = "";
        "LocalTimeZone"                    = "Eastern Standard Time";
    }
}

switch (Test-Path -Path $localSettingOutPath) {
    $true {
        switch ($PSCmdlet.ShouldContinue("Local settings file already exists. Do you want to continue?", $localSettingOutPath)) {
            $false {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.IO.IOException]::new("User cancelled operation since a current local settings file already exists."),
                        "LocalSettingsExists.UserDeclined",
                        [System.Management.Automation.ErrorCategory]::ResourceExists,
                        $localSettingOutPath
                    )
                )
                break
            }
        }
        break
    }
}

if ($PSCmdlet.ShouldProcess($localSettingOutPath, "Write default local settings file")) {
    $localSettings | ConvertTo-Json | Out-File -FilePath $localSettingOutPath -Force
}