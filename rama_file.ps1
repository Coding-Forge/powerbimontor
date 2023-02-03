#Requires -Modules Az.Storage
param($Timer)

$global:erroractionpreference = 1

try
{
    $currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)    

    if ($Timer.IsPastDue) {
        Write-Host "PowerShell timer is running late!"
    }


    $config = Get-PBIMonitorConfig $currentPath

# scale up process - Begin
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.ServicePrincipal.AppId, ($config.ServicePrincipal.AppSecret | ConvertTo-SecureString -AsPlainText -Force)

    Connect-AzAccount -ServicePrincipal `
                      -Tenant $config.ServicePrincipal.TenantID `
                      -Credential $credential
    Start-Sleep -Seconds 10

    $subscription_id = "aeea5a13-27c4-40b5-b442-788b73f55a8a"
    Update-AzConfig -DefaultSubscriptionForLogin "EDO-PROD"

    Set-AzContext -SubscriptionId $subscription_id

    $plan = Get-AzAppServicePlan -ResourceGroupName "EDO-PBIMONITOR-001-P" -Name "FunctionAppEDOPBIMonitor001p"
    Write-Host "APP service plan Name - " $plan.Sku.Name
    
    Set-AzAppServicePlan -Name "FunctionAppEDOPBIMonitor001p" -ResourceGroupName "EDO-PBIMONITOR-001-P" -Tier "ElasticPremium" -WorkerSize "Large"
    
    Start-Sleep -Seconds 30
### - End

    
    New-Item -ItemType Directory -Path ($config.OutputPath) -ErrorAction SilentlyContinue | Out-Null
    
    $stateFilePath = "$($config.AppDataPath)\state.json"
    
    & "$($config.ScriptsPath)\Fetch - Catalog.ps1" -config $config -stateFilePath $stateFilePath
    
    Write-Host "End"    
}
catch {

   $ex = $_.Exception

    if ($ex.ToString().Contains("429 (Too Many Requests)")) {
        throw "429 Throthling Error - Need to wait before making another request..."
    }  

    Resolve-PowerBIError -Last

    throw    
}

#Set-AzureAppServicePlan -ResourceGroupName "EDO-PBIMONITOR-001-P" -Name "FunctionAppEDOPBIMonitor001p" -Tier "ElasticPremium" -NumberofWorkers 1 -WorkerSize "Small"

# scale down process - Begin
Set-AzAppServicePlan -Name "FunctionAppEDOPBIMonitor001p" -ResourceGroupName "EDO-PBIMONITOR-001-P" -Tier "ElasticPremium" -WorkerSize "Small"
### - End



From: Brandon Campbell <Brandon.Campbell@microsoft.com> 
Sent: Wednesday, November 16, 2022 4:54 PM
To: Lingisetty, Ramakrishna <ramakrishna.lingisetty@ecolab.com>
Subject: Powershell script

Caution: This email message originated from outside of the organization. DO NOT CLICK on links or open attachments unless you recognize the sender and know the content is safe. If you think it is suspicious, please report as suspicious. 

param(
    [string]$configFilePath = ".\Config.json"
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Write-Host "Current Path: $currentPath"

Write-Host "Config Path: $configFilePath"
if (Test-Path $configFilePath) {
    $config = Get-Content $configFilePath | ConvertFrom-Json

    # Default Values

    if (!$config.OutputPath) {        
        $config | Add-Member -NotePropertyName "OutputPath" -NotePropertyValue ".\\Data" -Force
    }

    if (!$config.ServicePrincipal.Environment) {
        $config.ServicePrincipal | Add-Member -NotePropertyName "Environment" -NotePropertyValue "Public" -Force           
    }
}
else {
    throw "Cannot find config file '$configFilePath'"
}

$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.ServicePrincipal.AppId, ($config.ServicePrincipal.AppSecret | ConvertTo-SecureString -AsPlainText -Force)

try {
    Connect-AzAccount -ServicePrincipal `
                      -Tenant $config.ServicePrincipal.TenantID `
                      -Credential $credential
    Start-Sleep -Seconds 10
    Write-Output "Connected to tenant"
}
catch {
    Write-Host "The command ran is not found"`n -ForegroundColor Blue
    Write-Host "Message: [$($_.Exception.Message)"] -ForegroundColor Red -BackgroundColor DarkBlue        
}

Write-Output "Got here so far so good"
#-CertificateThumbprint $connection.CertificateThumbprint

Get-AzContext -ListAvailable

# El Loop while intenta autentificar 3 veces cada 30 segundos en caso que falle la primer conexion

$subscription_id = "e338c313-35fd-4313-bb88-c4bd5b6e6c46"

### this doesn't work
Set-AzContext -Subscription $subscription_id

$plan = Get-AzAppServicePlan -ResourceGroupName "codeforge-rg" -Name "testme"

# imprime en consola la hora ajustada 

Write-Output $plan.Sku.Size   

# En este caso Valida si son las  7am  y el plan es estandar 

Write-Output $plan.Sku.Size
$sizeplan = $plan.Sku.Size

#::::::::::::::::::::::::::::::::::::::::::::::::::INSTRUCCIONES PARA SUBIR Y BAJAR RECURSOS ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if($sizeplan -eq "F1") {

 Set-AzAppServicePlan -Name "testme" -ResourceGroupName "codeforge-rg" -Tier "Standard"   -WorkerSize "Small"
  Write-Output $pant.Sku.Size
  Write-Output "entro f1"
}
if($sizeplan -eq "S1") {

Set-AzAppServicePlan -Name 'testme' -ResourceGroupName 'codeforge-rg' -Tier Free -WorkerSize Small
Write-Output $pant.Sku.Size
 Write-Output "entro s"
}


