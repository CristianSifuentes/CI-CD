# 12 · Glosario

> Términos de CI/CD, Azure y seguridad de la cadena de suministro, con su nombre en inglés tal como
> aparece en la documentación y en las herramientas.
> **Última revisión:** 24 de octubre de 2026.

[← Cheatsheet](11-cheatsheet.md) · [Índice](../README.md) · [Siguiente: Radar 2026 →](13-novedades-y-ciclo-de-vida.md)

---

| Término (EN) | Significado |
| --- | --- |
| **Agent / Runner** | Máquina (VM o contenedor) que ejecuta los jobs. *Agent* en Azure Pipelines, *runner* en GitHub Actions |
| **Agent pool / Runner group** | Conjunto de agentes/runners con permisos y capacidades comunes |
| **Approval / Check** | Control antes de que un stage use un recurso protegido (environment, service connection, pool) |
| **Artifact** | Resultado inmutable del build (zip, imagen, paquete) que se promueve entre ambientes |
| **Artifact attestation** | Declaración firmada (in-toto/Sigstore) sobre cómo y dónde se construyó un artefacto |
| **AVM (Azure Verified Modules)** | Biblioteca oficial de módulos Bicep y Terraform mantenida por Microsoft |
| **azd (Azure Developer CLI)** | CLI que aprovisiona y despliega apps desde plantillas (`azd up`) |
| **Bake time** | Tiempo de observación tras desplegar en un ring antes de avanzar al siguiente |
| **Blue-green deployment** | Dos ambientes idénticos; el tráfico cambia de uno a otro de golpe |
| **Branch policy / Ruleset** | Reglas sobre ramas: PR obligatorio, revisores, checks (Azure Repos / GitHub) |
| **Brownout** | Fallo intencional y temporal de una función obsoleta para avisar antes de su retiro |
| **Build once, deploy many** | Principio: un solo artefacto, el mismo en todos los ambientes |
| **Canary release** | Exponer la versión nueva a un porcentaje pequeño de tráfico y crecer según métricas |
| **Change fail rate** | % de despliegues que causan una falla que requiere intervención (DORA) |
| **Change lead time** | Tiempo desde el commit hasta producción (DORA) |
| **CODEOWNERS** | Archivo que asigna revisores obligatorios por ruta |
| **Concurrency group / Exclusive lock** | Mecanismo para que sólo un despliegue corra a la vez sobre un recurso |
| **Continuous Delivery** | Toda versión que pasa el pipeline está lista para producción (gate manual) |
| **Continuous Deployment** | Toda versión que pasa el pipeline llega a producción automáticamente |
| **Continuous Integration (CI)** | Integrar cambios pequeños con frecuencia, con build y pruebas automáticas |
| **Deployment job** | Job de Azure Pipelines ligado a un environment, con estrategias y lifecycle hooks |
| **Deployment rework rate** | % de despliegues no planeados para corregir incidentes en producción (DORA, desde 2024) |
| **Deployment slot** | Instancia paralela de una app de App Service/Functions para preproducción y swap |
| **Deployment stack** | Recurso de Azure que gestiona un conjunto de recursos como unidad, con *deny settings* |
| **Digest** | Hash `sha256:` que identifica de forma inmutable una imagen de contenedor |
| **DORA metrics** | Métricas de desempeño de entrega de software (throughput e inestabilidad) |
| **Drift** | Diferencia entre lo declarado en IaC y lo que realmente existe en la nube |
| **Environment** | Destino de despliegue con historial, reglas de protección y secretos/variables propios |
| **Ephemeral environment** | Ambiente temporal (p. ej. por PR) que se destruye al terminar |
| **Expand/contract** | Patrón de migración de esquema en fases compatible hacia atrás |
| **Feature flag** | Interruptor que activa código ya desplegado sin redesplegar |
| **Federated identity credential** | Relación de confianza en Entra ID con un emisor OIDC externo (issuer + subject + audience) |
| **Flaky test** | Prueba que pasa o falla sin cambios en el código |
| **GitOps** | Modelo donde un agente en el clúster reconcilia el estado con un repositorio Git (Flux, Argo CD) |
| **Golden path** | Camino estandarizado y soportado por la plataforma para construir y desplegar |
| **IaC (Infrastructure as Code)** | Infraestructura declarada en código versionado (Bicep, Terraform) |
| **Immutable subject claim** | Formato del `sub` de OIDC de GitHub que incluye IDs numéricos de owner y repo (2026) |
| **Lifecycle hooks** | Fases de un deployment job: `preDeploy`, `deploy`, `routeTraffic`, `postRouteTraffic`, `on` |
| **Lockfile (workflow dependencies)** | `.github/workflows/actions.lock`: fija acciones y dependencias transitivas a commits verificados |
| **Managed DevOps Pools (MDP)** | Servicio de Azure para pools de agentes propios administrados (sucesor de VMSS agents) |
| **Managed identity** | Identidad de Entra ID administrada por Azure para un recurso, sin secretos |
| **MCP (Model Context Protocol)** | Protocolo para que agentes de IA usen herramientas y datos (p. ej. Azure DevOps MCP Server) |
| **OIDC (OpenID Connect)** | Protocolo de identidad; en CI/CD permite cambiar un token del runner por un token de la nube |
| **Parallel job** | Unidad de capacidad de ejecución concurrente en Azure Pipelines |
| **PAT (Personal Access Token)** | Token de usuario; en Azure DevOps, los globales dejan de funcionar el 1-dic-2026 |
| **Pipeline decorator** | Extensión que inyecta pasos en todos los pipelines de una organización |
| **Poisoned Pipeline Execution (PPE)** | Ataque que modifica la definición del pipeline para ejecutar código malicioso |
| **Progressive delivery** | Liberación gradual (canary, rings, flags) con verificación automática |
| **Provenance** | Metadatos verificables del origen y proceso de build de un artefacto (SLSA) |
| **Push protection** | Bloqueo de un `git push` que contiene secretos |
| **Required template** | Check de Azure Pipelines que exige extender un template aprobado |
| **Reusable workflow** | Workflow de GitHub invocable con `workflow_call` |
| **Revision** | Snapshot inmutable de una Container App; base del tráfico dividido |
| **Ring deployment** | Despliegue por anillos de audiencia/región cada vez más amplios |
| **Rollback / Roll-forward** | Volver a la versión anterior / corregir con una versión nueva |
| **SBOM (Software Bill of Materials)** | Inventario de componentes de un artefacto (SPDX, CycloneDX) |
| **Service connection** | Credencial/configuración de Azure Pipelines para acceder a un servicio externo |
| **Shift-left** | Mover controles (pruebas, seguridad) a etapas tempranas del ciclo |
| **SLI / SLO / Error budget** | Indicador, objetivo y margen tolerable de falla de un servicio |
| **SLSA** | Marco de niveles de integridad de la cadena de suministro (*Supply-chain Levels for Software Artifacts*) |
| **Smoke test** | Prueba rápida post-despliegue que confirma que lo esencial funciona |
| **Stage** | Agrupación lógica de jobs en Azure Pipelines (build, dev, prod…) |
| **Swap** | Intercambio de slots en App Service (staging ↔ production) con warm-up |
| **Template expression** | Expresión `${{ }}` evaluada al compilar el YAML de Azure Pipelines |
| **Trunk-based development** | Integración continua a una rama principal con ramas de vida muy corta |
| **Trusted publishing** | Publicación de paquetes (npm, PyPI) autenticada por OIDC, sin tokens de larga vida |
| **What-if** | Previsualización de cambios de un despliegue ARM/Bicep o de un deployment stack |
| **Workload Identity Federation (WIF)** | Autenticación sin secretos de pipelines/apps ante Entra ID mediante tokens federados |

[← Cheatsheet](11-cheatsheet.md) · [Índice](../README.md) · [Siguiente: Radar 2026 →](13-novedades-y-ciclo-de-vida.md)
