# Ejemplos listos para copiar

[← Volver al índice](../README.md)

Plantillas de referencia **validadas automáticamente** en cada cambio (ver
[`.github/workflows/validate.yml`](../.github/workflows/validate.yml)). Están pensadas para una
API .NET 10 desplegada en Azure, pero la estructura aplica a cualquier stack.

> [!IMPORTANT]
> Los nombres (`miapp`, `rg-miapp-prod`, `sc-miapp-prod`, …) son marcadores. Reemplázalos por los
> tuyos y revisa cada comentario `# ...` antes de usar un ejemplo en producción.

## Contenido

| Carpeta / archivo | Qué demuestra |
| --- | --- |
| [`azure-pipelines/webapp-ci-cd.yml`](azure-pipelines/webapp-ci-cd.yml) | Pipeline multi-etapa: Build → Dev → Staging (slot) → Prod (swap) con rollback automático |
| [`azure-pipelines/templates/`](azure-pipelines/templates/) | Plantillas de *steps* y *jobs* reutilizables (build .NET, deploy a Web App, instalar Terraform) |
| [`azure-pipelines/infra-terraform.yml`](azure-pipelines/infra-terraform.yml) | Terraform con Workload Identity Federation: plan → aprobación → apply del plan guardado |
| [`azure-pipelines/infra-bicep.yml`](azure-pipelines/infra-bicep.yml) | Bicep: lint + what-if → deployment stack con `denyDelete` |
| [`github-actions/ci.yml`](github-actions/ci.yml) | CI .NET con permisos mínimos, acciones fijadas por SHA y dependency review |
| [`github-actions/cd-webapp.yml`](github-actions/cd-webapp.yml) | CD a App Service con OIDC, environments, atestación de procedencia y swap con rollback |
| [`github-actions/reusable-deploy-webapp.yml`](github-actions/reusable-deploy-webapp.yml) | Workflow reutilizable (`workflow_call`) de despliegue + health check |
| [`github-actions/cd-containerapps.yml`](github-actions/cd-containerapps.yml) | Blue-green en Container Apps: imagen por digest, revisiones, etiquetas y tráfico |
| [`github-actions/infra-terraform.yml`](github-actions/infra-terraform.yml) | Terraform con OIDC: plan en PR, apply aprobado en `main` |
| [`github-actions/infra-bicep.yml`](github-actions/infra-bicep.yml) | Bicep con `azure/bicep-deploy`: what-if en PR, deployment stack en `main` |
| [`bicep/`](bicep/) | App Service plan + Web App + slot `staging` + App Insights, sin autenticación básica |
| [`terraform/`](terraform/) | La misma infraestructura con AzureRM 5.x y backend en Azure Storage con Entra ID |

> [!NOTE]
> Las acciones de los workflows están fijadas por SHA a las versiones vigentes al 24-oct-2026
> (el tag va en el comentario). Al copiarlas a `.github/workflows/` de tu repositorio, activa
> Dependabot para `github-actions` y se mantendrán al día con PRs.

## Estructura esperada en tu repositorio

```text
.
├── .github/workflows/        # ← workflows de github-actions/ (si usas GitHub)
├── azure-pipelines/          # ← pipelines y templates/ (si usas Azure Pipelines)
├── infra/
│   ├── bicep/                # ← examples/bicep
│   └── terraform/            # ← examples/terraform (+ backend.hcl real)
├── src/MiApp.Api/            # tu aplicación
└── tests/MiApp.Tests/        # tus pruebas
```

## Prerrequisitos comunes

### 1. Identidades sin secretos

| Plataforma | Qué crear | Dónde se configura la confianza |
| --- | --- | --- |
| Azure Pipelines | Service connection **Azure Resource Manager → Workload identity federation** (automática o manual con identidad administrada) | Credencial federada con emisor `https://login.microsoftonline.com/<tenant>/v2.0` (emisor Entra, el predeterminado desde 2025) |
| GitHub Actions | App registration o **identidad administrada asignada por el usuario** + credencial federada | Emisor `https://token.actions.githubusercontent.com`, *subject* por environment o rama |

Detalle paso a paso: [GitHub Actions → OIDC](../docs/04-github-actions-azure.md#autenticación-oidc-con-azure-sin-secretos)
y [Azure Pipelines → service connections](../docs/03-azure-pipelines-yaml.md#service-connections-y-workload-identity-federation).

### 2. Roles RBAC (mínimo privilegio)

| Identidad | Rol sugerido | Alcance |
| --- | --- | --- |
| Despliegue de app (dev/prod) | `Website Contributor` | Resource group de la app |
| Push de imágenes | `AcrPush` | Container Registry |
| Despliegue en Container Apps | `Container Apps Contributor` | Resource group de la app |
| Terraform *plan* | `Reader` + `Storage Blob Data Contributor` | Suscripción / contenedor del estado |
| Terraform *apply* / Bicep stack | `Contributor` (+ `Azure Deployment Stack Owner` si usas deny settings) | Resource group gestionado |
| Identidad de la app | `AcrPull`, `Key Vault Secrets User`, … | Sólo los recursos que consume |

### 3. Environments con aprobaciones

- **Azure Pipelines**: *Pipelines → Environments* → `miapp-dev`, `miapp-staging`, `miapp-prod`,
  `infra-prod` → *Approvals and checks* (aprobadores, horario laboral, alertas de Azure Monitor,
  branch control para permitir sólo `main`).
- **GitHub**: *Settings → Environments* → `dev`, `staging`, `production`, `infra-prod` →
  *Required reviewers*, *Wait timer*, *Deployment branches and tags: main*. Las variables
  `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` van como **variables** (no son
  secretos) del repo o de cada environment.

### 4. Aplicación preparada para despliegues seguros

- Endpoint de salud **`/healthz`** que valide dependencias críticas (lo usan el *health check* de
  App Service, el *warm-up* del swap y los smoke tests).
- Lock files de NuGet (`<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>`) para
  `dotnet restore --locked-mode` y cachés deterministas.
- Migraciones de base de datos **compatibles hacia atrás** (patrón *expand/contract*), para que el
  swap y el rollback no rompan el esquema. Ver [estrategias de despliegue](../docs/05-estrategias-de-despliegue.md).

## Validar localmente

```bash
# GitHub Actions (incluye shellcheck de los bloques run:)
actionlint .github/workflows/*.yml

# Bicep
bicep lint infra/bicep/main.bicep && bicep build-params infra/bicep/main.bicepparam --stdout > /dev/null

# Terraform
terraform -chdir=infra/terraform fmt -check -recursive
terraform -chdir=infra/terraform init -backend=false && terraform -chdir=infra/terraform validate

# YAML en general
yamllint -c .yamllint.yml .
```

Para Azure Pipelines, el validador definitivo es el propio servicio: en el editor de pipelines usa
**Validate**, o llama a la API `Runs - Run Pipeline` con `previewRun: true` y `yamlOverride` para
obtener el YAML final expandido sin ejecutar nada. Este repositorio además valida la estructura
contra el esquema oficial con [`scripts/validate_azure_pipelines.py`](../scripts/validate_azure_pipelines.py).
