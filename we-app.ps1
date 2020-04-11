# WeApp - 
# 
# WeApp is an open source Azure deployment tool aiming to provide a great developer experience. It removes / reduces the complications in 
# Azure, e.g. Network configurations so the app developers can focus on what really matters to them: the apps. 
#
# Author: Gang Gao (gaogang@gmail.com) 
#
# Licensed under Apache License 2.0

function New-WeApp {
    <#
    .SYNOPSIS
        Creates a new simple public facing serverless App in Azure
    .PARAMETER projectName
        Name of the project to be created.
    .PARAMETER appName
        Name of the app to be created
    .PARAMETER runtime
        The solution's runtime stack
    .PARAMETER build
        build { accepted values - none, react}
    .PARAMETER size
        Size of server allocated to the solution { accepted values - small, medium, large }
    .PARAMETER repo
        Type of repository {accepted values - none, github}
    .PARAMETER repoUrl
        Url of an existing repository 
    .EXAMPLE
        New-WeApp -projectName bronzefat999 -runtime 'node|10.15' -build react -size small
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$projectName,

        [string]$appName = '',

        [ValidateNotNullOrEmpty()]
        [string]$runtime = 'node|10.15',

        [ValidateNotNullOrEmpty()]
        [string]$build = 'none',

        [ValidateNotNullOrEmpty()]
        [String]$size = 'small',

        [ValidateNotNullOrEmpty()]
        [String]$repo = 'github',

        [string]$repoUrl = ''
    )

    # Load configuration
    $config =(Get-Content 'config.json' | Out-String | ConvertFrom-Json)

    $subscription = $config.azure.subscription
    $region = $config.azure.region
    $tag = "$($config.azure.tag.key)=$($config.azure.tag.value)"
    $token = $config.github.token
    $groupExists = (az group exists --name $projectName --subscription $subscription)

    if ($groupExists -eq 'true') {
        Write-Host "Resource group $($projectName) exists..." -BackgroundColor "Green" -ForegroundColor "Black"
    } else {
        Write-output 'creating resource group...'
        az group create --location $region --name $projectName --subscription $subscription --tags $tag > $null
    }

    if ($appName -eq '') {
        # Create an simple public facing serverless app
        $appId = Get-Random -minimum 10000 -maximum 99999
        $appName = "$($projectName)app$($appId)"
    } else {
        $searchResults = az webapp list --subscription $subscription --resource-group bronzefat98 --query "[?name=='$($appName)']" | ConvertFrom-Json

        # Return error is appName is not unique 
        if ($searchResults.length -gt 0) {
            Write-Error "App $($appName) exists. Process stops"
            return;
        }
    }
    

    $servicePlanName = "$($appName)plan"
    $sku = ''

    if ($size -eq 'small') {
        $sku = 'S1'
    } elseif ($size -eq 'medium') {
        $sku = 'P2V2'
    } elseif ($size -eq 'large') {
       $sku = 'P3V2'
    } else {
        Write-Error "Unsupported app size - $($size). Process stops"
    }

    # Create service plan
    Write-output "Creating service plan - $($servicePlanName)..."
    az appservice plan create --name $servicePlanName --subscription $subscription --resource-group $projectName --location $region --sku $sku --tags $tag > $null

    # Create web app
    Write-output "Creating web app - name: $($appName) runtime: $($runtime) build $($build)..."
    az webapp create --name $appName --subscription $subscription --resource-group $projectName --runtime "`"$($runtime)`""  --plan $servicePlanName --tags $tag > $null

    # Sort out continuous integration
    if ($repo -eq 'github') {
        if ($repoUrl -eq '') {
            $repoUrl = "$($config.github.urlBase)/$($appName)"
            
            # Create new repo
            Write-output "Creating new repository in GitHub..."
            $reactTemplateUrl = 'https://github.com/bronze-xueyuan/node-template'
            switch($runtime.Substring(0, 4)) {
                'node' 
                {
                    if ($build -eq 'react') {
                        Write-output "Loading react template..."
                        $reactTemplateUrl = 'https://github.com/bronze-xueyuan/react-template'
                    } 

                    Write-Host "Fokring repo from $($reactTemplateUrl)..." -BackgroundColor "Blue" -ForegroundColor "Black"
                    New-GitHubRepositoryFork -Uri $reactTemplateUrl -NoStatus -AccessToken $token | Foreach-Object {$_ | Rename-GitHubRepository -NewName $appName -AccessToken $token -Confirm:$false} > $null
                }
                default
                {
                    Write-Host "Create a new repo..." -BackgroundColor "Green" -ForegroundColor "Black"
                    New-GitHubRepository -RepositoryName $projectName -AccessToken $token -AutoInit > $null
                }
            }
        }
        
        $slotName = 'development'

        Write-output "Creating deployment slot - $($slotName)"
        az webapp deployment slot create --name $appName --subscription $subscription --resource-group $projectName --slot $slotName > $null

        # Enable authenticated git deployment in your subscription from a private repo
        Write-Debug 'Setting up deployment credentials...'
        az webapp deployment source update-token --git-token $token --subscription $subscription > $null

        Write-Debug "Setting up github integration -  $($appName) -> $($repoUrl)"
        az webapp deployment source config --branch master --name $appName --subscription $subscription --repo-url $repoUrl --resource-group $projectName --slot $slotName > $null
    } else {
        Write-error "repo type $($repo) is not supported"
    }
    
    Write-Host "Application $($appName) created successfully" -BackgroundColor "Green" -ForegroundColor "Black"
}


