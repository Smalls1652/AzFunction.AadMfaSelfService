# Azure AD MFA Self-Service Automation Service

This is an Azure Function script that runs every 30 minutes to check for users who are not enabled for Azure AD Identity Protection, but have registered a MFA method to their account. It's useful when you're targeting a specific set of users in an Azure AD security group and not the entire tenant.

## Setup

### Build the `AzureAD.MFA.Pwsh` PowerShell module

#### Using PowerShell

1. Launch Powershell and navigate to the source code directory for this Function app.
2. Type in `.\Initialize-AadMfaModule.ps1` and press enter.

#### Using Visual Studio Code

1. Open up the source code directory for this project in Visual Studio Code.
2. Run the **Build** task either by:
    - Selecting `Terminal -> Run Build Task...` in the top menu bar.
    - Using the keyboard shortcut for `Run Build Task`.
      - **Windows**: `Ctrl + Shift + B`