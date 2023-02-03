param(
    [string]$configFilePath = ".\Config.json"
)

$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

#Import-Module "$currentPath\Fetch - Utils.psm1" -Force

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

### Disable-AzContextAutosave –Scope Process

#Desactive el guardado automático de credenciales de Azure. La información de inicio de sesión se olvidará la próxima vez que abra una ventana de PowerShell‎

### $connection = Get-AutomationConnection -Name AzureRunAsConnection

#El runbook o la configuración tienen acceso a las propiedades de una conexión mediante el cmdlet interno.‎Get-AutomationConnection


$logonAttempt = 0
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.ServicePrincipal.AppId, ($config.ServicePrincipal.AppSecret | ConvertTo-SecureString -AsPlainText -Force)

#$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPassword
#Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
##
## add your service principal to the contributor role of the resource group this will make sure the context 
## has your subscription information as well
##
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

while(!($connectionResult) -and ($logonAttempt -le 3))
{
    $LogonAttempt++
 
    try {
        $connectionResult = Connect-AzAccount -ServicePrincipal `
                            -Tenant $config.ServicePrincipal.TenantID `
                            -Credential $credential
        Start-Sleep -Seconds 30
        Write-Output "Connected to tenant"
        Write-Output "did this return anything" + $connectionResult -eq $null
    }
    catch {
        Write-Host "The command ran is not found"`n -ForegroundColor Blue
        Write-Host "Message: [$($_.Exception.Message)"] -ForegroundColor Red -BackgroundColor DarkBlue        
    }
}

Write-Output "Got here so far so good"
#-CertificateThumbprint $connection.CertificateThumbprint



# El Loop while intenta autentificar 3 veces cada 30 segundos en caso que falle la primer conexion

$subscription_id = "e338c313-35fd-4313-bb88-c4bd5b6e6c46"

Set-AzContext -Subscription $subscription_id

$plan = Get-AzAppServicePlan -ResourceGroupName "codeforge-rg" -Name "testme"

# imprime en consola la hora ajustada 

Write-Output $plan.Sku.Size   

# En este caso Valida si son las  7am  y el plan es estandar 

Write-Output $plan.Sku.Size
$sizeplan = $plan.Sku.Size

$plan.Sku.Name

#::::::::::::::::::::::::::::::::::::::::::::::::::INSTRUCCIONES PARA SUBIR Y BAJAR RECURSOS ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if($sizeplan -eq "F1") {

Set-AzAppServicePlan -Name "testme" -ResourceGroupName "codeforge-rg" -Tier "Standard" -WorkerSize "Small" 
    Write-Output $pant.Sku.Size
    Write-Output "entro f1"
}
if($sizeplan -eq "S1") {

Set-AzAppServicePlan -Name 'testme' -ResourceGroupName 'codeforge-rg' -Tier "F1" -WorkerSize "Small"
    Write-Output $pant.Sku.Size
    Write-Output "entro s"
}