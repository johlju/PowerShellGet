#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'
                CertificateFile = $env:DscPublicCertificatePath

                Module1_Name     = 'PSLogging'
                Module2_Name     = 'SqlServer'

                Module2_RequiredVersion = '21.0.17279'
                Module2_MinimumVersion = '21.0.17199'
                Module2_MaximumVersion = '21.1.18068'
            }
        )
    }
}

<#
    .SYNOPSIS
        Changes the repository (package source) 'PSGallery' to not trusted.

    .NOTES
        Since the module is installed by SYSTEM as default this is done in
        case the PSGallery is already trusted for SYSTEM.
#>
Configuration MSFT_PSModule_SetPackageSourceAsNotTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name               = 'PSGallery'
            InstallationPolicy = 'Untrusted'
        }
    }
}

<#
    .SYNOPSIS
        Installs a module as trusted.

    .NOTES
        This assumes that the package source 'PSGallery' is not trusted for SYSTEM.
#>
Configuration MSFT_PSModule_InstallWithTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name               = $Node.Module1_Name
            InstallationPolicy = 'Trusted'
        }
    }
}

<#
    .SYNOPSIS
        Uninstalls a module ($Node.Module1_Name).
#>
Configuration MSFT_PSModule_UninstallModule1_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Module1_Name
        }
    }
}

<#
    .SYNOPSIS
        Changes the repository (package source) 'PSGallery' to trusted.

    .NOTES
        Since the module is installed by SYSTEM as default, the package
        source 'PSGallery' must be trusted for SYSTEM for some of the
        tests.
#>
Configuration MSFT_PSModule_SetPackageSourceAsTrusted_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSRepository 'Integration_Test'
        {
            Name               = 'PSGallery'
            InstallationPolicy = 'Trusted'
        }
    }
}

<#
    .SYNOPSIS
        Installs a module with the default parameters.
#>
Configuration MSFT_PSModule_DefaultParameters_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name = $Node.Module1_Name
        }
    }
}

<#
    .SYNOPSIS
        Installed a module using AllowClobber.

    .NOTES
        This test uses SqlServer module that actually needs AllowClobber.
        On the build worker there are other modules (SQLPS) already installed,
        those modules have the same cmdlets in them.
#>
Configuration MSFT_PSModule_UsingAllowClobber_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name         = $Node.Module2_Name
            AllowClobber = $true
        }
    }
}

<#
    .SYNOPSIS
        Uninstalls a module ($Node.Module2_Name).
#>
Configuration MSFT_PSModule_UninstallModule2_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.Module2_Name
        }
    }
}

<#
    .SYNOPSIS
        Installs a module with the specific version.
#>
Configuration MSFT_PSModule_RequiredVersion_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name            = $Node.Module2_Name
            RequiredVersion = $Node.Module2_RequiredVersion
            AllowClobber    = $true
        }
    }
}

<#
    .SYNOPSIS
        Installs a module with the specific version.
#>
Configuration MSFT_PSModule_RequiredVersion_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name            = $Node.Module2_Name
            RequiredVersion = $Node.Module2_RequiredVersion
            AllowClobber    = $true
        }
    }
}

<#
    .SYNOPSIS
        Installs a module within the specific version range.
#>
Configuration MSFT_PSModule_VersionRange_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name           = $Node.Module2_Name
            MinimumVersion = $Node.Module2_MinimumVersion
            MaximumVersion = $Node.Module2_MaximumVersion
            AllowClobber   = $true
        }
    }
}

#region Regression test for issue #451 - uninstalling a module that is in use
<#
    .SYNOPSIS
        Installs SqlServer module that should be made
        in use.

    .NOTES
        The issue #451 was reproduced using the module
        SqlServer v21.1.18068.
#>
Configuration MSFT_PSModule_InstallModuleThatShouldBeInUse_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Name               = 'SqlServer'
            RequiredVersion    = '21.1.18068'
            InstallationPolicy = 'Trusted'
        }
    }
}

<#
    .SYNOPSIS
        Use Script resource to import the SqlServer module
        into the current session, and creates an object of
        the Microsoft.AnalysisServices.Server class which
        loads the assembly into the session which prevents
        the folder from being deleted.

    .NOTES
        The issue #451 was reproduced using the module
        SqlServer v21.1.18068.
#>
Configuration MSFT_PSModule_ImportModuleToBeInUse_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        Script 'ImportPoshGitModule'
        {
            SetScript  = {
                $moduleName = 'SqlServer'

                <#
                    Make sure the correct version gets imported
                    into the session.
                #>
                $module = Get-Module -Name $moduleName
                if ($module)
                {
                    if ($module.Version -ne '21.1.18068')
                    {
                        Remove-Module -Name $moduleName -Force
                    }
                }

                Write-Verbose -Message ('Importing the module ''{0}'' (v21.1.18068) into the current session.' -f $moduleName)
                Import-Module -Name $moduleName -RequiredVersion '21.1.18068' -Force -Verbose:$false

                Write-Verbose -Message ('Use the class ''Microsoft.AnalysisServices.Server'' from an assembly in the imported module ''{0}'' (v21.1.18068).' -f $moduleName)
                # This will lock the assembly file 'DataSec.PAL.Interfaces.dll' in the module root folder.
                $sql = New-Object -TypeName 'Microsoft.AnalysisServices.Server'
            }

            TestScript = {
                $moduleName = 'SqlServer'

                Write-Verbose -Message ('Evaluating if the module ''{0}'' (v21.1.18068) is imported into the current session.' -f $moduleName)

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                if ($getScriptResult.Result -eq $moduleName)
                {
                    Write-Verbose -Message ('The module ''{0}'' (v21.1.18068) is already imported.' -f $moduleName)
                    $result = $true
                }
                else
                {
                    Write-Verbose -Message ('The module ''{0}'' (v21.1.18068) is not imported.' -f $moduleName)
                    $result = $false
                }

                return $result
            }

            GetScript  = {
                [System.String] $resultModuleName = $null

                $moduleName = 'SqlServer'

                $module = Get-Module -Name $moduleName
                if ($module)
                {
                    <#
                        Make sure the correct version is loaded
                        that is required for the regression test.
                    #>
                    if ($module.Version -eq '21.1.18068')
                    {
                        $resultModuleName = $module.Name
                    }
                }

                return @{
                    Result = $resultModuleName
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Uninstalls the module that is in use.
#>
Configuration MSFT_PSModule_UninstallModuleThatIsInUse_Config
{
    Import-DscResource -ModuleName 'PowerShellGet'

    node $AllNodes.NodeName
    {
        PSModule 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = 'SqlServer'
        }
    }
}
#endregion Regression test for issue #451 - uninstalling a module that is in use
