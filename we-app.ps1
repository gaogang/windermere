# WeApp - 
# 
# WeApp is an open source Azure deployment tool aiming to provide a great developer experience in the cloud. It removes the complications in 
# Azure, e.g. Network configurations so the app developers can focus on what really matters to them: the apps. 
#
# Author: Gang Gao (gaogang@gmail.com) 
#
# Licensed under Apache License 2.0

function New-WeApp {
    <#
    .SYNOPSIS
        Creates a new simple public facing serverless App in Azure
    .PARAMETER solutionName
        Name of the solution to be created.
    .PARAMETER runtime
        The solution's runtime stack
    .PARAMETER size
        Size of server allocated to the solution { small, medium, large }
    .PARAMETER repo
        Type of repository (Accepted values - none, github)
    .EXAMPLE
        New-WeApp -solutionName bronzefat999 -runtime '"node|10.15"' -size small
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$solutionName,

        [ValidateNotNullOrEmpty()]
        [string]$runtime = '"node|10.15"',

        [ValidateNotNullOrEmpty()]
        [String]$size = 'small',

        [ValidateNotNullOrEmpty()]
        [String]$repo = 'github',

        [string]$repoUrl = ''
    )

    $DebugPreference = "Continue"

    # Load configuration
    $config =(Get-Content 'config.json' | Out-String | ConvertFrom-Json)

    $subscription = $config.azure.subscription
    $region = $config.azure.region
    $tag = "$($config.azure.tag.key)=$($config.azure.tag.value)"
    $token = $config.github.token
    $groupExists = (az group exists --name $solutionName --subscription $subscription)

    if ($groupExists -eq 'true') {
        Write-Debug 'Resource group exists...'
    } else {
        Write-Debug 'creating resource group...'
        az group create --location $region --name $solutionName --subscription $subscription --tags $tag > $null
    }

    # Create an simple public facing serverless app
    $appName = "$($solutionName)app"
    
    $servicePlanName = "$($solutionName)plan"
    $sku = $size

    if ($size -eq 'small') {
        $sku = 'S1'
    } elseif ($size -eq 'medium') {
        $sku = 'P2V2'
    } elseif ($size -eq 'large') {
       $sku = 'P3V2'
    } else {
        Write-Error "Unsupported app size - $($size)"
    }

    # Create service plan
    Write-Debug "Creating service plan..."
    az appservice plan create --name $servicePlanName --subscription $subscription --resource-group $solutionName --location $region --sku $sku --tags $tag > $null

    # Create web app
    Write-Debug 'Creating web app...'
    az webapp create --name $appName --subscription $subscription --resource-group $solutionName --runtime $runtime --plan $servicePlanName --tags $tag > $null

    # Sort out continuous integration
    if ($repo -eq 'github') {
        if ($repoUrl -eq '') {
            $repoUrl = "$($config.github.urlBase)/$($solutionName)"
            
            # Create new repo
            Write-Debug "Creating new repository in GitHub..."
            New-GitHubRepository -RepositoryName $solutionName -AccessToken $token -AutoInit > $null
        }
        
        $slotName = 'development'

        Write-Debug "Create deployment slot - $($slotName)"
        az webapp deployment slot create --name $appName --subscription $subscription --resource-group $solutionName --slot $slotName > $null

        # Enable authenticated git deployment in your subscription from a private repo
        Write-Debug 'Setting up deployment credentials...'
        az webapp deployment source update-token --git-token $token --subscription $subscription > $null

        Write-Debug "Setting up github integration -  $($appName) -> $($repoUrl)"
        az webapp deployment source config --branch master --name $appName --subscription $subscription --repo-url $repoUrl --resource-group $solutionName --slot $slotName > $null
    }
    
    Write-Debug "Solution $($solutionName) created successfully"
}



