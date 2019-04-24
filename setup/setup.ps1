[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$True)]
    [string]$AlertEmail
)

$creds = Get-Credential

$0 = $myInvocation.MyCommand.Definition
$CommandDirectory = [System.IO.Path]::GetDirectoryName($0)
Push-Location $CommandDirectory

Connect-AzureRmAccount -Credential $creds

if ($null -eq (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Ignore)) {
    throw "The Resources Group '$ResourceGroupName' doesn't exist."
}

Write-Host "Resource Group Name: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Deploying ARM Template ... " -ForegroundColor Yellow -NoNewline

Push-Location "..\arm"
$DeploymentName = "LogicAppAlerts-" + ((Get-Date).ToUniversalTime()).ToString("MMdd-HHmm")
$ArmParamsObject = @{"AlertEmail"=$AlertEmail}
$DeploymentOutput = New-AzureRmResourceGroupDeployment -Mode Incremental -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile "logicapp-alerts.json" -TemplateParameterObject $ArmParamsObject
Write-Host "Done" -ForegroundColor Yellow

Push-Location $CommandDirectory