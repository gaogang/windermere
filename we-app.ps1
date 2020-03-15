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
        [string]$user = 'gaogang'
    )

    $region = 'uksouth'
    $tag = 'windermere0521'

    # Replace 'token' with your github personal access token
    # Goto https://github.com/settings/tokens to generate a new PAT
    $token = 'token'

    # Create github
    'Creating github repository...'
    New-GitHubRepository -RepositoryName $solutionName -AccessToken $token -AutoInit > $null

    # Enable authenticated git deployment in your subscription from a private repo
    'Setting up deployment credentials...'
    az functionapp deployment source update-token --git-token $token > $null

    "creating resource group..."
    az group create --location $region --name $solutionName --tags $tag > $null

    # Create an Azure storage account in the resource group.
    'Creating storage account...'
    $storageName = "$($solutionName)storage"

    az storage account create --name $storageName --location $region --resource-group $solutionName --sku Standard_LRS --tags $tag > $null

    # Create an simple public facing serverless app
    'Creating a simple public facing serverless app'
    $functionAppName = "$($solutionName)app"

    az functionapp create --name $functionAppName --storage-account $storageName --consumption-plan-location $region --resource-group $solutionName --runtime $Runtime --functions-version 2 --tags $tag > $null

    # Sort out continuous integration
    "Setting up github integration -  $($functionAppName) -> https://github.com/$($user)/$($solutionName)"
    az functionapp deployment source config --branch master --name $functionAppName --repo-url "https://github.com/$($user)/$($solutionName)" --resource-group $solutionName > $null

    "Solution $($solutionName) created successfully"
}

