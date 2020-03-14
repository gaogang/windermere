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
    $token = '22f940c0b3964f2240f0276fe9172d8cd3c519ae'

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

