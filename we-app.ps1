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
        Size of server allocated to the solution { small, medium, big, dontcare - auto scale, pay as you go and any value native to Azure }
    .PARAMETER repo
        Type of repository (Accepted values - none, github)
    .PARAMETER user
        Github user
    .EXAMPLE
        New-WeApp -solutionName bronzefat999 -runtime node
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$solutionName,

        [ValidateNotNullOrEmpty()]
        [string]$runtime = 'node',

        [ValidateNotNullOrEmpty()]
        [String]$size = 'dontcare',

        [ValidateNotNullOrEmpty()]
        [String]$repo = 'none',

        [ValidateNotNullOrEmpty()]
        [string]$user = 'gaogang'
    )

    # Load configuration
    $config =(Get-Content 'config.json' | Out-String | ConvertFrom-Json)

    $subscription = $config.azure.subscription
    $region = $config.azure.region
    $tag = 'windermere0521'

    # Replace 'token' with your github personal access token
    # Goto https://github.com/settings/tokens to generate a new PAT
    $token = $config.github.token

    # Create github
    if ($repo -eq 'github') {
        'Creating github repository...'
        New-GitHubRepository -RepositoryName $solutionName -AccessToken $token -AutoInit > $null
    }

    # Enable authenticated git deployment in your subscription from a private repo
    'Setting up deployment credentials...'
    az functionapp deployment source update-token --git-token $token --subscription $subscription > $null

    $groupExists = (az group exists --name $solutionName --subscription $subscription)

    if ($groupExists -eq 'true') {
        Write-Log -Message 'Resource group exists...' -Level Debug
    } else {
        "creating resource group..."
        az group create --location $region --name $solutionName --subscription $subscription --tags $tag > $null
    }

    # Create an Azure storage account in the resource group.
    'Creating storage account...'
    $storageName = "$($solutionName)storage"

    az storage account create --name $storageName --subscription $subscription --location $region --resource-group $solutionName --sku Standard_LRS --tags $tag > $null

    # Create an simple public facing serverless app
    'Creating a simple public facing serverless app'
    $functionAppName = "$($solutionName)app"

    
    if ($size -eq 'dontcare') {
        # Create function with Consumption plan
        az functionapp create --name $functionAppName --subscription $subscription --storage-account $storageName --resource-group $solutionName --runtime $runtime --functions-version 2 --tags $tag > $null
    } else {
        $servicePlanName = "$($solutionName)plan"
        $sku = $size

        if ($size -eq 'small') {
            $sku = 'S1'
        } elseif ($size -eq 'medium') {
            $sku = 'P1V2'
        } elseif ($size -eq 'large') {
            $sku = 'P3V2'
        }

        # Create service plan
        az appservice plan create --name $servicePlanName --subscription $subscription --resource-group $solutionName --sku $sku --tags $tag > $null

        # Create function
        az functionapp create --name $functionAppName --subscription $subscription --storage-account $storageName --resource-group $solutionName --runtime $runtime --functions-version 2 --plan $servicePlanName --tags $tag > $null
    }

    # Sort out continuous integration
    if ($repo -eq 'github') {
        "Setting up github integration -  $($functionAppName) -> https://github.com/$($user)/$($solutionName)"
        az functionapp deployment source config --branch master --name $functionAppName --subscription $subscription --repo-url "https://github.com/$($user)/$($solutionName)" --resource-group $solutionName > $null
    }
    
    "Solution $($solutionName) created successfully"
}



