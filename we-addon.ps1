function Add-WeApi {
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
        [String]$repo = 'none'
    )

    # Load configuration
    $config =(Get-Content 'config.json' | Out-String | ConvertFrom-Json)

    $subscription = $config.azure.subscription
    $region = $config.azure.region
    $tag = 'windermere0521'

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
        $user = $config.github.user

        "Setting up github integration -  $($functionAppName) -> https://github.com/$($user)/$($solutionName)"
        az functionapp deployment source config --branch master --name $functionAppName --subscription $subscription --repo-url "https://github.com/$($user)/$($solutionName)" --resource-group $solutionName > $null
    }
    
    "Solution $($solutionName) created successfully"
}

function Add-WeDb {
    <#
    .SYNOPSIS
        Add a database to an app
    .PARAMETER solutionName
        Name of the solution the addon is attached to
    .PARAMETER database
        The type of the database - currently only cosmos db is supported
    .EXAMPLE
        New-WeDbAddon -appName bronzefat -database cosmos
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$solutionName,

        [ValidateNotNullOrEmpty()]
        [string]$database = 'cosmos'
    )

    if ($database -ne 'cosmos') {
        throw "Database type - $($database) is not supported"
    }

    # Check if the solution exists
    $resourceGroupExists = (az group exists --name $solutionName)

    if ($resourceGroupExists -eq 'false') {
        $message = 'Resource group does not exists'
        Write-Log -Message $message -Level Error

        throw $message
    } 

    # Load configuration
    $config =(Get-Content 'config.json' | Out-String | ConvertFrom-Json)
    $region = $config.azure.region
    $subscription = $config.azure.subscription
    $tag = 'windermere0521'

    # Create a VNet
    $vnetName = "$($solutionName)vnet"
    $dbSubnetName = "$($solutionName)DbSubnet"
    $vnet = (az network vnet create --name $vnetName --resource-group $solutionName --subscription $subscription --location $region --subnet-name $dbSubnetName --tag $tag)

    # Disable subnet private endpoint policies
    az network vnet subnet update --name $dbSubnetName --resource-group $solutionName --subscription $subscription --vnet-name $vnetName --disable-private-endpoint-network-policies true
    
    # Create cosmos db
    $cosmosDbAccount = "$($solutionName)cdb"
    $cosmosDb = (az cosmosdb create --name $cosmosDbAccount --resource-group $solutionName --subscription $subscription --enable-virtual-network true --tag $tag)

    # Create a private endpoint
    $privateEndpointName = "$($solutionName)pep"        # private endpoint
    $privateLinkName = "$($solutionName)pl"             # private link

    $cosmosDbJson = $cosmosDb | ConvertFrom-Json        # convert cosmosDb creation output to Json so we can extract the id of the cosmos db we just created
    az network private-endpoint create --name $privateEndpointName --resource-group $solutionName --subscription $subscription --location $region --vnet-name $vnetName --subnet $dbSubnetName --private-connection-resource-id $cosmosDbJson.id --connection-name $privateLinkName --group-id Sql --tags $tag

    # create a service endpoint to the app so the app can get access to the database
    $appSubnetName = "$($solutionName)AppSubnet"

    # Work out subnet ip
    $vnetJson = $vnet | ConvertFrom-Json 
    $subnetIpAddr = $vnetJson.newVNET.subnets[0].addressPrefix.split(".")
    $appSubnetIpAddr = "$($subnetIpAddr[0]).$($subnetIpAddr[1]).$(($subnetIpAddr[2] -as [int]) + 1).$($subnetIpAddr[3])" 

    az network vnet subnet create --name $appSubnetName --vnet-name $vnetName --subscription $subscription --resource-group $solutionName --address-prefixes $appSubnetIpAddr
    
    az webapp vnet-integration add  --name "$($solutionName)app" --subscription $subscription --resource-group $solutionName --vnet $vnetName --subnet $appSubnetName

    'Database added successfully'
}