$scriptRoot = $PSScriptRoot

Write-Information -InformationAction "Continue" -MessageData "- Downloading AzureAD.MFA.Pwsh source code"
$tempForCurrentUser = [System.IO.Path]::GetTempPath()
$tempWorkingDir = [System.IO.Path]::Join($tempForCurrentUser, "azmfaselfservice-workingdir\")

switch (Test-Path -Path $tempWorkingDir) {
    $true {
        Remove-Item -Path $tempWorkingDir -Force -Recurse
        break
    }
}

$null = New-Item -Path $tempWorkingDir -ItemType "Directory"

$zipDownloadUri = "https://github.com/Smalls1652/AzureAD.MFA.Pwsh.Utils/archive/refs/heads/main.zip"

$ProgressPreference = "SilentlyContinue"
$zipDownloadReq = Invoke-WebRequest -Uri $zipDownloadUri -Method "Get"
$ProgressPreference = "Continue"

$contentDispositionData = [System.Net.Mime.ContentDisposition]::new($zipDownloadReq.Headers['Content-Disposition'])
$mfaUtilsRepoZipFilePath = [System.IO.Path]::Join($tempWorkingDir, $contentDispositionData.FileName)

[System.IO.File]::WriteAllBytes($mfaUtilsRepoZipFilePath, $zipDownloadReq.Content)

Write-Information -InformationAction "Continue" -MessageData "- Expanding source code archive"
Expand-Archive -Path $mfaUtilsRepoZipFilePath -DestinationPath $tempWorkingDir

Write-Information -InformationAction "Continue" -MessageData "- Building the 'AzureAD.MFA.Pwsh' PowerShell module"
$mfaUtilsRepoPath = [System.IO.Path]::Join($tempWorkingDir, "AzureAD.MFA.Pwsh.Utils-main\")
Push-Location -Path $mfaUtilsRepoPath -StackName "mfautils-codedir"

try {
    $builtMfaUtilsModule = . ".\RunModuleBuild.ps1"
}
finally {
    Pop-Location -StackName "mfautils-codedir"
}

Write-Information -InformationAction "Continue" -MessageData "- "

$azFuncModulesDir = [System.IO.Path]::Join($scriptRoot, "Modules\")
switch (Test-Path -Path $azFuncModulesDir) {
    $true {
        Remove-Item -Path $azFuncModulesDir -Force -Recurse
        break
    }
}

$null = New-Item -Path $azFuncModulesDir -ItemType "Directory"
Copy-Item -Path $builtMfaUtilsModule -Destination $azFuncModulesDir -Recurse

Remove-Item -Path $tempWorkingDir -Force -Recurse