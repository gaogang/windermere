function Add-WeConnectToSalesforce {
    <#
    .SYNOPSIS
        Add a database to an app
    .PARAMETER solutionName
        Name of the solution the addon is attached to
    .EXAMPLE
        New-WeConnectToSalesforce -appName bronzefat -database cosmos
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$solutionName
    )

    throw 'Add-WeConnectToSales is under construction'
}