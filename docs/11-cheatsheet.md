# 11 · Cheatsheet

> Comandos y fragmentos que se usan todos los días. Copia, adapta, ejecuta.
> **Última revisión:** 24 de octubre de 2026 · Azure CLI 2.91 · azd 1.37 · Bicep 0.48 · Terraform 1.17.

[← Troubleshooting](10-troubleshooting.md) · [Índice](../README.md) · [Siguiente: Glosario →](12-glosario.md)

---

## En esta guía

- [Azure CLI: sesión, grupos y RBAC](#azure-cli-sesión-grupos-y-rbac)
- [Identidades federadas (OIDC/WIF)](#identidades-federadas-oidcwif)
- [App Service y Functions](#app-service-y-functions)
- [Container Apps y ACR](#container-apps-y-acr)
- [AKS y Kubernetes](#aks-y-kubernetes)
- [Bicep y deployment stacks](#bicep-y-deployment-stacks)
- [Terraform](#terraform)
- [Azure DevOps CLI](#azure-devops-cli)
- [GitHub CLI](#github-cli)
- [Azure Developer CLI](#azure-developer-cli)
- [Expresiones: Azure Pipelines vs. GitHub Actions](#expresiones-azure-pipelines-vs-github-actions)

---

## Azure CLI: sesión, grupos y RBAC

```bash
az login                                   # interactivo (MFA); en CI se usa OIDC/WIF
az account set --subscription "<id-o-nombre>"
az account show -o table

az group create -n rg-miapp-prod -l mexicocentral --tags environment=prod owner=plataforma
az group list --query "[?tags.environment=='prod'].name" -o tsv

# RBAC mínimo para una identidad (object ID del service principal / identidad administrada)
az role assignment create --assignee-object-id <principal-id> --assignee-principal-type ServicePrincipal \
  --role "Website Contributor" --scope "/subscriptions/<sub>/resourceGroups/rg-miapp-prod"
az role assignment list --assignee <principal-id> --all -o table

# Resource providers (AzureRM 5.x ya no los registra solo)
az provider register --namespace Microsoft.Web
az provider show -n Microsoft.Web --query registrationState -o tsv
```

## Identidades federadas (OIDC/WIF)

```bash
# Identidad administrada asignada por el usuario
az identity create -g rg-identidades -n id-github-miapp-prod
az identity show -g rg-identidades -n id-github-miapp-prod --query "{clientId:clientId, principalId:principalId}"

# Credencial federada para un environment de GitHub (formato inmutable en repos nuevos)
gh api repos/<owner>/<repo> --jq '"owner_id=\(.owner.id) repo_id=\(.id)"'
az identity federated-credential create -g rg-identidades --identity-name id-github-miapp-prod \
  --name gh-production --issuer https://token.actions.githubusercontent.com \
  --subject "repo:<owner>@<owner_id>/<repo>@<repo_id>:environment:production" \
  --audiences api://AzureADTokenExchange

# App registration en lugar de identidad administrada
az ad app create --display-name sp-github-miapp-prod
az ad app federated-credential create --id <app-object-id> --parameters credential.json
az ad app federated-credential list --id <app-object-id> -o table
```

## App Service y Functions

```bash
az webapp deploy -g <rg> -n <app> --src-path webapp.zip --type zip [--slot staging]
az webapp deployment slot create -g <rg> -n <app> --slot staging --configuration-source <app>
az webapp deployment slot swap -g <rg> -n <app> --slot staging --target-slot production
az webapp deployment slot swap -g <rg> -n <app> --slot staging --action preview   # swap con preview
az webapp deployment slot swap -g <rg> -n <app> --slot staging --action reset     # cancelar preview
az webapp traffic-routing set -g <rg> -n <app> --distribution staging=10           # 10 % al slot
az webapp traffic-routing clear -g <rg> -n <app>
az webapp config appsettings set -g <rg> -n <app> --settings KEY=valor [--slot-settings KEY2=valor]
az resource update -g <rg> -n scm --namespace Microsoft.Web --resource-type basicPublishingCredentialsPolicies \
  --parent sites/<app> --set properties.allow=false                                # sin auth básica
az webapp log tail -g <rg> -n <app>

az functionapp deployment source config-zip -g <rg> -n <func> --src func.zip
az functionapp show -g <rg> -n <func> --query "{state:state, kind:kind}"
```

## Container Apps y ACR

```bash
az acr login -n <registry>                              # con la identidad de la sesión (OIDC)
az acr build -r <registry> -t miapp:{{.Run.ID}} .       # build en la nube (ACR Tasks)
az acr repository show-tags -n <registry> --repository miapp --orderby time_desc --top 5
az acr import -n <registry-prod> --source <registry-dev>.azurecr.io/miapp@sha256:<digest> -t miapp:1.5.0

az containerapp update -n <app> -g <rg> --image <registry>.azurecr.io/miapp@sha256:<digest> --revision-suffix <sufijo>
az containerapp revision list -n <app> -g <rg> -o table
az containerapp revision set-mode -n <app> -g <rg> --mode multiple
az containerapp revision label add -n <app> -g <rg> --label green --revision <app>--<sufijo> --yes
az containerapp ingress traffic set -n <app> -g <rg> --label-weight green=10 blue=90
az containerapp ingress traffic show -n <app> -g <rg>
az containerapp registry set -n <app> -g <rg> --server <registry>.azurecr.io --identity system
az containerapp logs show -n <app> -g <rg> --follow
```

## AKS y Kubernetes

```bash
az aks get-credentials -g <rg> -n <aks>                  # con Entra ID: usa kubelogin
az aks get-upgrades -g <rg> -n <aks> -o table
az aks upgrade -g <rg> -n <aks> --kubernetes-version 1.37
az aks update -g <rg> -n <aks> --auto-upgrade-channel stable
az aks update -g <rg> -n <aks> --attach-acr <registry>
az aks check-acr -g <rg> -n <aks> --acr <registry>.azurecr.io

kubectl rollout status deploy/miapp -n miapp
kubectl rollout history deploy/miapp -n miapp
kubectl rollout undo deploy/miapp -n miapp [--to-revision=3]
kubectl set image deploy/miapp api=<registry>.azurecr.io/miapp@sha256:<digest> -n miapp
helm upgrade --install miapp ./chart -n miapp --atomic --wait --timeout 10m
helm rollback miapp 3 -n miapp
```

## Bicep y deployment stacks

```bash
bicep lint main.bicep
bicep build main.bicep --stdout > /dev/null
bicep build-params main.bicepparam --stdout > /dev/null
bicep decompile template.json                      # ARM JSON → Bicep (punto de partida)

az deployment group what-if -g <rg> -f main.bicep -p main.bicepparam
az deployment group create  -g <rg> -f main.bicep -p main.bicepparam --name "deploy-$(date +%Y%m%d%H%M)"
az deployment sub create -l mexicocentral -f sub.bicep

az stack group create -n <stack> -g <rg> -f main.bicep -p main.bicepparam \
  --action-on-unmanage detachAll --deny-settings-mode denyDelete --yes
az stack group show -n <stack> -g <rg>
az stack group delete -n <stack> -g <rg> --action-on-unmanage detachAll --yes
```

## Terraform

```bash
terraform init -backend-config=backend.hcl          # -backend=false para validar sin estado
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=prod.tfvars -out=tfplan -detailed-exitcode   # 0 sin cambios, 2 cambios, 1 error
terraform show -no-color tfplan
terraform apply tfplan
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64
terraform state list
terraform import 'azurerm_resource_group.this' /subscriptions/<sub>/resourceGroups/rg-miapp-prod
terraform force-unlock <LOCK_ID>                     # sólo si confirmaste que no hay otra ejecución

# OIDC en CI
export ARM_USE_OIDC=true ARM_CLIENT_ID=<client-id> ARM_TENANT_ID=<tenant-id> ARM_SUBSCRIPTION_ID=<sub-id>
```

## Azure DevOps CLI

```bash
az extension add --name azure-devops
az devops configure --defaults organization=https://dev.azure.com/<org> project=<proyecto>

az pipelines list -o table
az pipelines create --name miapp-ci-cd --repository <repo> --repository-type tfsgit --branch main --yml-path azure-pipelines/webapp-ci-cd.yml
az pipelines run --name miapp-ci-cd --branch main --parameters deployToProd=false
az pipelines runs list --top 10 -o table
az pipelines variable-group list -o table
az devops service-endpoint list -o table
az repos pr list --status active -o table
```

> En pipelines, autentica estos comandos con `AzureCLI@3` y una service connection de tipo
> **Azure DevOps** (`connectionType: azureDevOps`) en lugar de un PAT.

## GitHub CLI

```bash
gh workflow list
gh workflow run cd-webapp.yml --ref main
gh run list --workflow cd-webapp.yml --limit 5
gh run watch <run-id>
gh run view <run-id> --log-failed
gh run rerun <run-id> --failed [--debug]
gh attestation verify webapp.zip --repo <owner>/<repo>
gh attestation verify oci://<registry>.azurecr.io/miapp@sha256:<digest> --repo <owner>/<repo>
gh api repos/<owner>/<repo>/environments --jq '.environments[].name'
gh secret set NOMBRE --env production          # si de verdad necesitas un secreto
gh variable set AZURE_CLIENT_ID --env production --body <client-id>
```

## Azure Developer CLI

```bash
azd auth login
azd init                      # o: azd init --template <plantilla>
azd provision                 # sólo infraestructura
azd deploy                    # sólo código
azd up                        # provision + deploy
azd pipeline config --provider github   # o azdo: crea pipeline + credencial federada
azd env list
azd down --purge              # elimina el ambiente (¡cuidado!)
```

## Expresiones: Azure Pipelines vs. GitHub Actions

| Necesidad | Azure Pipelines | GitHub Actions |
| --- | --- | --- |
| Sólo en `main` | `condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')` | `if: github.ref == 'refs/heads/main'` |
| No en PR | `ne(variables['Build.Reason'], 'PullRequest')` | `if: github.event_name != 'pull_request'` |
| Si falló algo antes | `condition: failed()` | `if: failure()` |
| Siempre, salvo cancelación | `condition: not(canceled())` | `if: ${{ !cancelled() }}` |
| Valor de otro job | `$[ dependencies.build.outputs['meta.tag'] ]` | `${{ needs.build.outputs.tag }}` |
| Fijar una salida | `echo "##vso[task.setvariable variable=tag;isOutput=true]v1"` | `echo "tag=v1" >> "$GITHUB_OUTPUT"` |
| Variable de entorno para pasos siguientes | `echo "##vso[task.setvariable variable=X]1"` | `echo "X=1" >> "$GITHUB_ENV"` |
| Agregar al PATH | `echo "##vso[task.prependpath]/opt/tool"` | `echo "/opt/tool" >> "$GITHUB_PATH"` |
| Enmascarar un valor | `echo "##vso[task.setvariable variable=s;issecret=true]valor"` | `echo "::add-mask::valor"` |
| Resumen del job | `echo "##vso[task.uploadsummary]resumen.md"` | `cat resumen.md >> "$GITHUB_STEP_SUMMARY"` |
| Condicional en compilación | `${{ if eq(parameters.env, 'prod') }}:` | (no existe; usa `if:` o matrices) |
| Ternario | `${{ iif(eq(parameters.env,'prod'),'P1v3','B1') }}` | `${{ inputs.env == 'prod' && 'P1v3' \|\| 'B1' }}` |

[← Troubleshooting](10-troubleshooting.md) · [Índice](../README.md) · [Siguiente: Glosario →](12-glosario.md)
