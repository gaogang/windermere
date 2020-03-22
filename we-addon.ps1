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
    
    $region = 'uksouth'
    $tag = 'windermere0521'

    if ($resourceGroupExists -eq 'false') {
        $message = 'Resource group does not exists'
        Write-Log -Message $message -Level Error

        throw $message
    } 

    # Create a VNet
    $vnetName = "$($solutionName)vnet"
    $dbSubnetName = "$($solutionName)DbSubnet"
    $vnet = (az network vnet create --name $vnetName --resource-group $solutionName --location $region --subnet-name $dbSubnetName --tag $tag)

    # Disable subnet private endpoint policies
    az network vnet subnet update --name $dbSubnetName --resource-group $solutionName --vnet-name $vnetName --disable-private-endpoint-network-policies true
    
    # Create cosmos db
    $cosmosDbAccount = "$($solutionName)cdb"
    $cosmosDb = (az cosmosdb create --name $cosmosDbAccount --resource-group $solutionName --enable-virtual-network true --tag $tag)

    # Create a private endpoint
    $privateEndpointName = "$($solutionName)pep"        # private endpoint
    $privateLinkName = "$($solutionName)pl"             # private link

    $cosmosDbJson = $cosmosDb | ConvertFrom-Json        # convert cosmosDb creation output to Json so we can extract the id of the cosmos db we just created
    az network private-endpoint create --name $privateEndpointName --resource-group $solutionName --location $region --vnet-name $vnetName --subnet $dbSubnetName --private-connection-resource-id $cosmosDbJson.id --connection-name $privateLinkName --group-id Sql --tags $tag

    # create a service endpoint to the app so the app can get access to the database
    $appSubnetName = "$($solutionName)AppSubnet"

    # Work out subnet ip
    $subnetIpAddr = $vnetJson.newVNET.subnets[0].addressPrefix.split(".")
    $appSubnetIpAddr =  "$($subnetIpArr[0]).$($subnetIpArr[1]).$(($subnetIpArr[2] -as [int]) + 1).$($subnetIpArr[3])" 

    az network vnet subnet create --name $appSubnetName --vnet-name $vnetName --resource-group $solution --address-prefixes $appSubnetIpAddr
    
    az webapp vnet-integration add  --name "$($solutionName)app" --resource-group $solutionName --vnet $vnetName --subnet $appSubnetName

    'Database added successfully'
}