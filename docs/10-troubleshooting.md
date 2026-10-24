# 10 · Troubleshooting

> Errores frecuentes en Azure Pipelines, GitHub Actions y despliegues a Azure, con su causa probable
> y la solución. Úsala con `Ctrl+F` buscando el mensaje de error.
> **Última revisión:** 24 de octubre de 2026.

[← Observabilidad](09-observabilidad-y-operacion.md) · [Índice](../README.md) · [Siguiente: Cheatsheet →](11-cheatsheet.md)

---

## En esta guía

- [Método de diagnóstico](#método-de-diagnóstico)
- [Identidad y autenticación (Entra ID, OIDC, WIF)](#identidad-y-autenticación-entra-id-oidc-wif)
- [Azure Pipelines](#azure-pipelines)
- [GitHub Actions](#github-actions)
- [App Service y Functions](#app-service-y-functions)
- [Container Apps y AKS](#container-apps-y-aks)
- [Bicep, ARM y Terraform](#bicep-arm-y-terraform)
- [Comandos de diagnóstico](#comandos-de-diagnóstico)

---

## Método de diagnóstico

1. **¿Qué cambió?** Commit del pipeline, versión de imagen del agente/runner (`-latest` se mueve),
   versión de tareas/acciones, permisos, políticas de Azure, fechas de retiro (ver [Radar](13-novedades-y-ciclo-de-vida.md)).
2. **Sube el detalle de logs**: Azure Pipelines → variable `System.Debug: true`; GitHub → secretos o
   variables `ACTIONS_STEP_DEBUG=true` y `ACTIONS_RUNNER_DEBUG=true` (o "Re-run with debug logging").
3. **Reproduce localmente** con la misma versión de herramientas (`az`, `terraform`, `bicep`, SDK).
4. **Revisa el estado del servicio**: [status.dev.azure.com](https://status.dev.azure.com),
   [githubstatus.com](https://www.githubstatus.com), [Azure status](https://azure.status.microsoft/) y
   *Service Health* de tu suscripción.
5. **Aísla**: ejecuta el paso fallido en un pipeline/workflow mínimo.

---

## Identidad y autenticación (Entra ID, OIDC, WIF)

| Mensaje | Causa probable | Solución |
| --- | --- | --- |
| `AADSTS700213: No matching federated identity record found for presented assertion subject` | El *subject* del token no coincide con ninguna credencial federada | GitHub: el *subject* real aparece en el log de `azure/login` (*Federated token details → subject claim*); revisa `environment:` vs `ref:` y el **formato inmutable** (`repo:owner@id/repo@id:...`). ADO: usa el emisor/subject que muestra la service connection (Entra vs. `vstoken.dev.azure.com`) |
| `AADSTS7002138: ... matches with case-insensitive comparison, but not with case-sensitive comparison` | Mayúsculas/minúsculas distintas en org, repo, rama o environment | El *subject* se compara **sensible a mayúsculas**: cópialo exactamente del log |
| Error de *audience* en el intercambio del token | La credencial federada no usa `api://AzureADTokenExchange` | Usa la audiencia por defecto en la credencial y en `azure/login` |
| `AADSTS700024: Client assertion is not within its valid time range` | El token federado expiró (scripts largos que reutilizan `$idToken`) | Pide el token justo antes de usarlo; en Terraform usa el modo en que el provider refresca tokens (`ARM_ADO_PIPELINE_SERVICE_CONNECTION_ID` + `SYSTEM_ACCESSTOKEN`) |
| `AADSTS70025: ... has no configured federated identity credentials` | La identidad no tiene credenciales federadas | Crea la credencial federada (o convierte la service connection) |
| `AADSTS700016: Application ... was not found in the directory` | `client-id`/tenant equivocado | Verifica `AZURE_CLIENT_ID` y `AZURE_TENANT_ID` del environment |
| `AADSTS50076` / "you must use multi-factor authentication" en CLI | Automatización con **cuenta de usuario**: MFA obligatorio en Azure desde oct-2025 | Migra a service principal o identidad administrada con federación |
| `AuthorizationFailed ... does not have authorization to perform action` | Falta RBAC (o el rol aún se propaga) | Asigna el rol mínimo al alcance correcto; espera unos minutos tras crearlo |
| 401 al usar un PAT en Azure DevOps | PAT expirado, global (dejan de funcionar el **1-dic-2026**) o bloqueado por política | PAT de una sola organización con scopes mínimos o, mejor, token de Entra |

---

## Azure Pipelines

| Mensaje / síntoma | Causa | Solución |
| --- | --- | --- |
| `No hosted parallelism has been purchased or granted` | Organización sin la capa gratis habilitada | Vincula una suscripción de Azure en *Billing* (activa la capa gratuita) o compra jobs paralelos |
| `The job running on agent ... ran longer than the maximum time of 60 minutes` | Límite de la capa gratuita | Divide el job, optimiza, o compra paralelismo (360 min por job) |
| `No agent found in pool ... which satisfies the specified demands` | *Demands* no cubiertas, pool sin agentes en línea o sin permiso | Revisa `demands`, el `ImageOverride` del Managed DevOps Pool y los permisos del pool para el pipeline |
| `Step input azureSubscription references service connection ... which could not be found` | Nombre incorrecto, falta autorización o la conexión fue **deshabilitada por 100 días sin uso** | Corrige el nombre, autoriza el pipeline en *Pipeline permissions* o rehabilita la conexión |
| La service connection muestra advertencia de emisor | Usa el emisor Azure DevOps (`vstoken.dev.azure.com`), que se retira el **1-jul-2027** | Botón *Update* para convertir al emisor Entra (actualiza la credencial federada si es manual) |
| Jobs fallan en ventanas programadas con imágenes viejas | *Brownout* de una imagen obsoleta (p. ej. `macOS-14` en oct-2026, `ubuntu-22.04` en mar–abr-2027) | Cambia `vmImage` a una imagen soportada |
| Tarea falla tras el 24-nov-2026 con errores de *handler* de Node | Se eliminaron Node 6/10/16 del agente | Actualiza la tarea o extensión; prueba con *Restrict out of support Node.js versions* |
| `docker: Cannot connect to the Docker daemon` dentro de un *container job* | `mapDockerSocket` es `false` por defecto (agente 5.279.0+) | `mapDockerSocket: true` en el recurso del contenedor, sólo si realmente lo necesitas |
| El agente self-hosted no arranca tras actualizarse | Agente v5 requiere un SO soportado por **.NET 10** | Actualiza el SO; usa el script `FindAgentsNotCompatibleWithAgent` antes |
| `Unexpected value 'xyz'` / `A template expression is not allowed in this context` | Sintaxis YAML o expresión en lugar no permitido | Valida en el editor (*Validate*); recuerda: `${{ }}` compila, `$[ ]` runtime, `$( )` macro |
| La variable de salida llega vacía | Falta `name:` en el step, `isOutput=true` o la sintaxis de `dependencies`/`stageDependencies` | Ver [variables de salida](03-azure-pipelines-yaml.md#variables-de-salida-output-variables) |
| El stage se saltó sin explicación | Condición evaluada a `false` o deseleccionado al encolar | Desde 2026 la UI indica el motivo del *skip*; revisa `condition` y `dependsOn` |
| El PR de Azure Repos no dispara el pipeline | `pr:` no aplica a Azure Repos | Configura la *branch policy* de **Build validation** |

---

## GitHub Actions

| Mensaje / síntoma | Causa | Solución |
| --- | --- | --- |
| `Unable to get ACTIONS_ID_TOKEN_REQUEST_URL env variable` | Falta `permissions: id-token: write`, o es un PR de fork | Agrega el permiso al job (y al job que llama al reusable workflow) |
| `Resource not accessible by integration` | Permisos insuficientes del `GITHUB_TOKEN` | Declara el permiso necesario (`contents: write`, `pull-requests: write`, …) sólo en ese job |
| `The nested job ... is requesting 'id-token: write', but is only allowed 'none'` | El llamador no otorgó el permiso al reusable workflow | Los permisos sólo se reducen al anidar: otórgalos en el job que hace `uses:` |
| `Branch "x" is not allowed to deploy to production due to environment protection rules` | Regla de ramas del environment | Despliega desde `main` o ajusta la regla |
| El job queda "Waiting" indefinidamente | Revisores requeridos o *wait timer* | Aprueba en la UI; las aprobaciones expiran a los 30 días |
| `checkout` rechaza el código del PR en `pull_request_target` | `actions/checkout` v7 bloquea forks en contextos privilegiados | Rediseña con `pull_request` + `workflow_run`; `allow-unsafe-pr-checkout` sólo tras revisar el riesgo |
| Advertencia: no se pudo guardar la caché | Disparador de baja confianza con caché de sólo lectura (2026) o `cache-mode: read` | Esperado: deja que un workflow de `push` mantenga la caché |
| Acción antigua falla o avisa sobre Node | Node 20 se eliminó de los runners el **23-sep-2026** | Actualiza a versiones `node24` de las acciones (checkout v7, setup-* actuales, etc.) |
| `This request has been automatically failed because it uses a deprecated version of ...` | Versión mayor retirada de una acción oficial | Actualiza a la versión mayor vigente |
| Job cancelado a los 15 minutos en `ubuntu-slim` | Límite de *timeout* de los runners de 1 vCPU | Usa `ubuntu-24.04` para trabajos largos |
| El workflow no aparece/dispara | YAML inválido, archivo > 500 KB o evento/filtro de ramas incorrecto | Ejecuta `actionlint`; revisa `on:` y `paths` |

---

## App Service y Functions

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `409 Conflict` al desplegar | Otro despliegue en curso al mismo sitio/slot | Serializa con `concurrency` (GitHub) o *Exclusive lock* (ADO) |
| `401/403` en Kudu/SCM al desplegar con *publish profile* | Autenticación básica deshabilitada (correcto) | Despliega con Entra ID (OIDC/WIF) en lugar de publish profile |
| Swap falla por *warm-up timeout* | La app no responde 200 en la ruta de warm-up | Revisa `WEBSITE_SWAP_WARMUP_PING_PATH/STATUSES`, tiempo de arranque, dependencias en `/healthz` |
| Tras el swap la app usa configuración equivocada | *Slot settings* mal marcados | Marca como "deployment slot setting" sólo lo que debe quedarse en el slot |
| `Container didn't respond to HTTP pings on port` | El contenedor no escucha en el puerto esperado | Configura `WEBSITES_PORT` y escucha en `0.0.0.0` |
| La app no arranca tras el 10-nov-2026 | Runtime .NET 8/9 sin soporte o modelo *in-process* de Functions | Migra a .NET 10 y al *isolated worker* |
| Flex Consumption: error de acceso al *deployment storage* | La identidad no tiene rol sobre el contenedor de despliegue | Asigna rol de datos de blob a la identidad configurada para el despliegue |

---

## Container Apps y AKS

| Síntoma | Causa | Solución |
| --- | --- | --- |
| Revisión en `Failed` / `ImagePullBackOff` | La identidad de la app/kubelet no tiene **AcrPull** o el registry no está configurado con identidad | `az containerapp registry set --identity ...`; en AKS `az aks check-acr` y `az aks update --attach-acr` |
| `revision suffix ... already exists` | Sufijo repetido (re-ejecución) | Incluye el intento en el sufijo (`<sha>-r<attempt>`) |
| El tráfico no llega a la revisión nueva | Tráfico fijado a otras revisiones/etiquetas o modo `single` | Revisa `az containerapp ingress traffic show`; pesos deben sumar 100 |
| `CrashLoopBackOff` | La app falla al iniciar (config/secretos) | `kubectl logs --previous`, revisa *probes* y variables |
| Rollout de AKS atascado | *Readiness probe* nunca pasa | `kubectl rollout status`, `kubectl describe pod`; corrige probe o recursos |
| Upgrade de AKS bloqueado | APIs obsoletas o PDB que impide drenar | *Diagnose and solve problems → Kubernetes API deprecations*; ajusta PDB |
| Ingress deja de recibir parches | ingress-nginx retirado (mar-2026) y app routing NGINX sin parches tras nov-2026 | Migra a Gateway API (app routing con Istio) o Application Gateway for Containers |

---

## Bicep, ARM y Terraform

| Mensaje | Causa | Solución |
| --- | --- | --- |
| `MissingSubscriptionRegistration` | Resource provider no registrado (AzureRM 5.x ya no los registra) | `az provider register --namespace Microsoft.Web` (con una identidad de plataforma) |
| `RequestDisallowedByPolicy` | Una Azure Policy con efecto `deny` | Ajusta el recurso a la política o solicita una exención documentada |
| `DenyAssignmentAuthorizationFailed` | Un *deployment stack* con deny settings protege el recurso | Cambia el recurso desde el stack (pipeline) o excluye la identidad en `deny-settings-excluded-principals` |
| `InvalidTemplate` / `BCP...` | Error de sintaxis o tipo en Bicep | `bicep build` / `bicep lint` localmente |
| What-if muestra cambios "fantasma" | Ruido de propiedades calculadas | Revisa sólo cambios relevantes; en stacks (2026) hay reducción de ruido |
| `Error acquiring the state lock` | Otro plan/apply en curso o un lock huérfano | Espera (`-lock-timeout=5m`); `terraform force-unlock <ID>` sólo si confirmas que no hay otra ejecución |
| `Saved plan is stale` | El estado cambió entre plan y apply | Genera un plan nuevo y vuelve a aprobar |
| `subscription_id is a required provider property` | AzureRM 4.x+ exige la suscripción | Exporta `ARM_SUBSCRIPTION_ID` |
| `Failed to get existing workspaces: ... AuthorizationPermissionMismatch` | Backend sin rol de datos o usando keys | `use_azuread_auth = true` + **Storage Blob Data Contributor** |
| `building account: could not acquire access token` (OIDC) | Variables `ARM_*` incompletas o token expirado | `ARM_USE_OIDC=true`, `ARM_CLIENT_ID`, `ARM_TENANT_ID` y el token (GitHub: `id-token: write`) |
| Hashes inválidos en `.terraform.lock.hcl` | Lock file generado sólo para una plataforma | `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64` |

---

## Comandos de diagnóstico

```bash
# Identidad y RBAC
az account show -o table
az role assignment list --assignee <principal-id> --all -o table
az ad app federated-credential list --id <app-object-id> -o table
az identity federated-credential list -g <rg> --identity-name <identidad> -o table

# Despliegues de ARM
az deployment group list -g <rg> --query "[].{name:name, state:properties.provisioningState, ts:properties.timestamp}" -o table
az deployment operation group list -g <rg> -n <deployment> --query "[?properties.provisioningState=='Failed']"

# App Service
az webapp log tail -g <rg> -n <app>
az webapp deployment list-publishing-profiles -g <rg> -n <app> --query "[].publishMethod"   # sólo para auditar

# Container Apps
az containerapp revision list -n <app> -g <rg> -o table
az containerapp logs show -n <app> -g <rg> --follow

# AKS
kubectl get events -A --sort-by=.lastTimestamp | tail -30
kubectl rollout status deploy/<nombre> -n <ns>
az aks check-acr -g <rg> -n <aks> --acr <registry>.azurecr.io

# Azure DevOps (CLI)
az pipelines runs list --top 10 -o table
az pipelines runs show --id <run-id>
```

[← Observabilidad](09-observabilidad-y-operacion.md) · [Índice](../README.md) · [Siguiente: Cheatsheet →](11-cheatsheet.md)
