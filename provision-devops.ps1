# ------------------------------------------------------------
# 0. Variables à personnaliser --------------------------------
# ------------------------------------------------------------
$orgUrl    = "https://dev.azure.com/DamiEchate"            # URL de ton organisation DevOps
$project   = "Spring"                                     # Nom du projet DevOps
$rg        = "rg-springweb"                               # Resource Group Azure
$location  = "westeurope"                                 # Région Azure
$acrName   = "springacr$((Get-Random -Max 99999))"        # Doit être unique globalement
$webApp    = "springweb-app"                              # Nom de ta Web App
$svcName   = "AzureRM-Springweb"                          # Nom de la Service Connection
# ------------------------------------------------------------

# 1. Installer Az + extension Azure DevOps
if (-not (Get-Module -ListAvailable Az)) {
    Write-Host "➡️  Installation du module Az..."
    Install-Module Az -Scope CurrentUser -Force -AllowClobber
}
# Ignore les erreurs pip au besoin pour azure-devops
Write-Host "➡️  Installation de l'extension azure-devops (si manquante)..."
try {
    if (-not (az extension list --query "[?name=='azure-devops']" -o tsv)) {
        az extension add --name azure-devops --yes
    }
} catch {
    Write-Warning "⚠️  Extension azure-devops déjà ou pip a échoué, on continue..."
}

# 2. Authentification
Write-Host "➡️  Connexion Azure CLI..."
az login            # ouvre le navigateur
az account set --subscription "Azure for Students"

# 3. Création des ressources Azure
Write-Host "➡️  Création du Resource Group..."
az group create -n $rg -l $location | Out-Null

Write-Host "➡️  Enregistrement du provider ContainerRegistry..."
az provider register --namespace Microsoft.ContainerRegistry | Out-Null

Write-Host "➡️  Création de l'ACR..."
az acr create -n $acrName -g $rg --sku Basic --admin-enabled true | Out-Null

$plan = "$webApp-plan"
Write-Host "➡️  Création de l'App Service Plan..."
az appservice plan create -n $plan -g $rg --is-linux --sku B1 | Out-Null

Write-Host "➡️  Création de la Web App (Java 17)..."
az webapp create -n $webApp -g $rg --plan $plan --runtime "JAVA|17-java17" | Out-Null

# 4. Service Principal + rôles
Write-Host "➡️  Génération du Service Principal et assignation des rôles..."
$subId = az account show --query id -o tsv
$sp    = az ad sp create-for-rbac `
            --name "spn-$svcName" `
            --role Contributor `
            --scopes "/subscriptions/$subId/resourceGroups/$rg" `
            --sdk-auth | ConvertFrom-Json

# Grant AcrPush sur l’ACR
az role assignment create `
    --assignee $sp.appId `
    --role AcrPush `
    --scope (az acr show -n $acrName -g $rg --query id -o tsv) | Out-Null

# 5. Service Connection Azure RM dans Azure DevOps
Write-Host "➡️  Configuration Azure DevOps (service connection)..."
az devops configure --defaults organization=$orgUrl project=$project

$pat = Read-Host -AsSecureString "PAT DevOps (scopes: Service Connections + Read/Write)"
$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pat)
$plainPat = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$env:AZURE_DEVOPS_EXT_PAT = $plainPat

az devops service-endpoint azurerm create `
    --name $svcName `
    --azure-rm-service-principal-id  $sp.appId `
    --azure-rm-service-principal-key $sp.password `
    --azure-rm-tenant-id             $sp.tenant `
    --subscription                   $subId `
    --resource-group                 $rg `
    --output none

# 6. Variable Group dans Azure DevOps
Write-Host "➡️  Création du Variable Group..."
az pipelines variable-group create `
    --name "Springweb-vars" `
    --authorize true `
    --variables `
        ACR_NAME=$acrName `
        WEBAPP=$webApp `
        RG=$rg | Out-Null

Write-Host "`n✅  Tous les prérequis Azure & DevOps sont en place :
   • Service connection : $svcName
   • Variable group      : Springweb-vars
   • ACR                 : $acrName

Tu peux maintenant pousser ton code et lancer (ou relancer) le pipeline YAML." -ForegroundColor Green
