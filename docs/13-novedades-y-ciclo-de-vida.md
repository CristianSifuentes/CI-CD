# 13 · Radar 2026: novedades, retiros y fechas límite

> Lo que cambió en los últimos 12 meses y el calendario de lo que viene. Revisa esta página cada
> trimestre.
> **Estado al:** 24 de octubre de 2026.

[← Glosario](12-glosario.md) · [Índice](../README.md)

---

## En esta guía

- [Próximas fechas límite](#próximas-fechas-límite)
- [Novedades recientes por plataforma](#novedades-recientes-por-plataforma)
- [Versiones vigentes de referencia](#versiones-vigentes-de-referencia)
- [Revisión trimestral](#revisión-trimestral)
- [Cómo mantenerse al día](#cómo-mantenerse-al-día)

---

## Próximas fechas límite

> [!IMPORTANT]
> Ordenadas por fecha. 🔴 = acción urgente (≤ 60 días), 🟠 = planifícalo este trimestre, 🟢 = en el radar.

| Fecha | Qué ocurre | Impacto | Acción |
| --- | --- | --- | --- |
| 🔴 Oct-2026 (26, 29 y 30) | *Brownouts* restantes de **macOS 14** en Azure Pipelines | Jobs con `macOS-14` fallan en esas ventanas | Cambia a `macOS-15`/`macOS-latest` |
| 🔴 **2-nov-2026** | **macOS 14** eliminado de Azure Pipelines | Pipelines con esa imagen dejan de correr | Ídem |
| 🔴 **10-nov-2026** | Fin de soporte de **.NET 8** y **.NET 9** | Sin parches de seguridad | Migra a **.NET 10 LTS** (SDK, `TargetFramework`, runtime de App Service/Functions) |
| 🔴 **10-nov-2026** | Fin de soporte del modelo **in-process** de Azure Functions | Sin parches ni correcciones | Migra al **isolated worker** |
| 🔴 ≤ **15-nov-2026** | `windows-2025` de Azure Pipelines pasa a **Visual Studio 2026**; `windows-latest` apuntará a `windows-2025-vs2026` | Builds de .NET Framework/C++/MSBuild pueden cambiar | Prueba hoy con `windows-2025-vs2026` |
| 🔴 **24-nov-2026** | Se eliminan **Node.js 6, 10 y 16** del agente de Azure Pipelines | Tareas/extensiones viejas fallan | Activa *Restrict out of support Node.js versions* y actualiza tareas |
| 🔴 Nov-2026 | Fin de vida de **Kubernetes 1.34** en AKS | Sin parches de comunidad | Actualiza a 1.35+ (o LTS) |
| 🔴 Nov-2026 | Fin de parches de seguridad del add-on **application routing con NGINX** en AKS | Ingress sin parches | Migra a **Gateway API** (app routing con Istio) o App Gateway for Containers |
| 🔴 **1-dic-2026** | Los **PATs globales** de Azure DevOps dejan de funcionar | Integraciones y scripts con 401 | PATs de una organización o tokens de Entra; service connection *Azure DevOps* |
| 🟠 2026 (fecha por anunciar) | Retiro de la plataforma **Azure DevOps OAuth** | Apps OAuth propias dejan de autenticar | Migra a **Microsoft Entra ID OAuth** |
| 🟠 **31-ene-2027** | Retiro definitivo de **Azure Blueprints** (fases desde el 31-jul-2026) | Se borran definiciones/asignaciones y sus *locks* | Migra a **deployment stacks** + template specs |
| 🟠 2027 (fecha por anunciar) | Proyectos públicos de Azure DevOps se convierten en privados | Sin acceso anónimo; minutos de pipeline limitados | Migra lo público a GitHub |
| 🟠 23-mar → 14-abr-2027 | *Brownouts* de **Ubuntu 22.04** en Azure Pipelines | Jobs fallan en ventanas | Cambia a `ubuntu-24.04`/`ubuntu-26.04` |
| 🟠 **17-abr-2027** | **Ubuntu 22.04** retirado de Azure Pipelines y sin soporte en GitHub Actions | Imagen no disponible | Ídem |
| 🟠 Abr-2027 | **Node 20** se elimina del agente de Azure Pipelines; **Node 22** llega a EOL (30-abr-2027) | Tareas con handler Node 20 | Tareas en Node 24 |
| 🟢 **1-jun-2027** | AKS inicia **upgrades forzados por la plataforma** para versiones sin soporte | Upgrades fuera de ventana, ignorando PDBs | Canal `stable` + mantenimiento planificado |
| 🟢 **1-jul-2027** | Retiro del **emisor Azure DevOps** en service connections con WIF | Conexiones no convertidas fallan | Botón *Update* → emisor Entra |
| 🟢 **11-dic-2027** | **EU Cyber Resilience Act** en aplicación completa (reportes de vulnerabilidades desde 11-sep-2026) | Productos digitales vendidos en la UE | SBOM, gestión de vulnerabilidades, actualizaciones |
| 🟢 30-abr-2028 | EOL de **Node.js 24** | — | Planea Node 26 (LTS desde el 28-oct-2026) |
| 🟢 **30-sep-2028** | Retiro del plan **Consumption Linux** de Azure Functions | Apps en ese plan | Migra a **Flex Consumption** |
| 🟢 14-nov-2028 | Fin de soporte de **.NET 10** | — | Planea .NET 12 LTS |

---

## Novedades recientes por plataforma

### Azure DevOps (sprints 264–280)

| Fecha | Novedad |
| --- | --- |
| Nov-2025 | Servidor MCP **local** GA; nuevas organizaciones requieren suscripción de Azure; ampliación de Advanced Security |
| Dic-2025 | **Azure DevOps Server** (sin año) GA con *Modern Lifecycle Policy*; Windows Server 2019 retirado de los agentes hospedados |
| Ene-2026 | Integración **Azure Boards ↔ GitHub Copilot coding agent** GA; nuevo *Test Run Hub* |
| Feb-2026 | *Custom agents* de Copilot desde work items; mejor depuración de runs (motivos de *skip*/cancelación) |
| Mar-2026 | **Remote MCP Server** (*preview*); vista **Stages** y propiedad `group`; artefacto visible por run; PATs expirados no se pueden extender |
| Abr-2026 | **Code Search integrado**; retiro de proyectos públicos; CodeQL *default setup* (*preview*) |
| May-2026 | Agente Windows ARM64; comentarios para validar PRs de forks configurables por origen |
| Jun-2026 | Service connection **Azure DevOps** con identidad de Entra (sin PAT), `AzureCLI@3`; agentes **GitHub-hosted** de pago por minuto (Apple Silicon) en *preview* |
| Jul-2026 | **CodeQL default setup GA** (incluye C/C++); service connections sin uso 100 días se deshabilitan; emisor Azure DevOps de WIF obsoleto |
| Jul-2026 | Anotaciones de PR en tarjetas de Boards; `InvokeRESTAPI@1` con service connection Azure DevOps |
| Ago-2026 | **Remote MCP Server GA**; tokens de builds emitidos por Entra; nueva experiencia de cobertura de código |
| Sep-2026 | **Copilot code review para Azure Repos** (*public preview*); `mapDockerSocket: false` por defecto (agente 5.279+); agente v5 sobre .NET 10 |
| Oct-2026 | **Ubuntu 26.04** y **Windows Server 2025 + VS 2026** GA; Copilot Autofix agéntico; EPSS en alertas de dependencias |

### GitHub Actions

| Fecha | Novedad |
| --- | --- |
| 1-ene-2026 | Precios de runners hospedados reducidos hasta 39 %; el cargo a minutos self-hosted se pospuso |
| Mar–may 2026 | Incidentes de cadena de suministro (`trivy-action`/`setup-trivy`, `actions-cool`): refuerzan el pinning por SHA y los releases inmutables |
| **15-jul-2026** | **Subjects OIDC inmutables** por defecto en repos nuevos (`repo:owner@id/repo@id:...`) |
| 2026 | **Lockfile de dependencias de workflows** (*public preview*, `gh actions-lock`); pasos `background`/`parallel`/`wait`; `cache-mode` y caché de sólo lectura para disparadores de baja confianza; `ubuntu-slim`; imágenes personalizadas (`snapshot`) |
| 2026 | `actions/checkout@v7` bloquea checkout de forks en `pull_request_target`/`workflow_run`; `actions/attest@v4` reemplaza a `attest-build-provenance` para nuevas implementaciones |
| **23-sep-2026** | **Node 20 eliminado** de los runners: las acciones JavaScript corren en Node 24 |
| 2026 | `ubuntu-26.04` (x64 y arm64), `windows-latest` = Windows Server 2025 + VS 2026, `macos-latest` = macOS 26 arm64 |

### Azure

| Fecha | Novedad |
| --- | --- |
| 1-oct-2025 | **MFA obligatorio fase 2** (CLI, PowerShell, IaC, REST, SDK con cuentas de usuario) |
| Nov-2025 | **.NET 10 LTS** y Kubernetes 1.34 GA en AKS |
| Mar-2026 | Retiro comunitario de **ingress-nginx**; Kubernetes 1.35 GA en AKS |
| Mar–abr 2026 | Gateway API administrado y app routing con Istio GA en AKS; Argo CD como extensión (*preview*) |
| Jun-2026 | Kubernetes 1.36 GA en AKS |
| **27-jul-2026** | **AzureRM 5.0** (sin registro automático de resource providers, validación mejorada opcional) |
| 31-jul-2026 | Inicia el retiro por fases de **Azure Blueprints** |
| Ago-2026 | *What-if* para deployment stacks (`az stack-whatif`) con reducción de ruido |
| Ago–oct 2026 | Terraform 1.16 y **1.17 (Terraform Policy GA)**; Kubernetes **1.37** GA en AKS; Bicep 0.48 |

---

## Versiones vigentes de referencia

| Herramienta | Versión (oct-2026) | Notas |
| --- | --- | --- |
| .NET | **10 LTS** (11 en RC, GA esperada en nov-2026) | 8 y 9 terminan el 10-nov-2026 |
| Node.js | **24** (LTS mantenimiento), **26** (LTS desde 28-oct-2026), 22 (mantenimiento hasta abr-2027) | 20 ya es EOL |
| Kubernetes (AKS) | 1.35, 1.36, 1.37 | 1.34 EOL en nov-2026 |
| Azure CLI | 2.91 | |
| Azure Developer CLI | 1.37 | |
| Bicep | 0.48 | Preinstalado en runners/agentes hospedados |
| Terraform | 1.17 · AzureRM 5.11 · AzAPI 2.13 | OpenTofu 1.13 como alternativa |
| Agente de Azure Pipelines | v5 (5.281) | .NET 10 |
| Runner de GitHub Actions | 2.338 | |
| Acciones clave | `checkout@v7`, `setup-dotnet@v6`, `setup-node@v7`, `upload-artifact@v7`, `download-artifact@v8`, `cache@v6`, `azure/login@v3`, `azure/webapps-deploy@v3`, `azure/bicep-deploy@v2`, `actions/attest@v4`, `github/codeql-action@v4` | Fíjalas por SHA |

---

## Revisión trimestral

- [ ] Recorre la tabla de [fechas límite](#próximas-fechas-límite) y crea work items/issues con dueño.
- [ ] Busca imágenes, tareas y acciones obsoletas (`vmImage`, `runs-on`, `@vN`, `node16/node20`).
- [ ] Revisa service connections, credenciales federadas, PATs y apps OAuth (¿quedan secretos?).
- [ ] Actualiza versiones de SDKs y herramientas por PR (Dependabot/Renovate) y corre los pipelines.
- [ ] Revisa versiones de AKS y planifica el siguiente upgrade antes del EOL.
- [ ] Repasa métricas DORA y de salud del pipeline con el equipo.
- [ ] Actualiza esta guía (fecha de revisión al inicio de cada documento).

---

## Cómo mantenerse al día

| Fuente | Qué trae |
| --- | --- |
| [Azure DevOps release notes](https://learn.microsoft.com/azure/devops/release-notes/) y [roadmap](https://learn.microsoft.com/azure/devops/release-notes/features-timeline) | Cada sprint (~3 semanas) |
| [Blog de Azure DevOps](https://devblogs.microsoft.com/devops/) | Anuncios de retiros y cambios de seguridad |
| [Calendario de retiros de imágenes de Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/agents/hosted-deprecation-schedule) | *Brownouts* y fechas de eliminación |
| [actions/runner-images — anuncios](https://github.com/actions/runner-images/issues?q=label%3AAnnouncement) | Cambios de imágenes (GitHub y Azure Pipelines) |
| [GitHub Changelog](https://github.blog/changelog/) | Novedades y deprecaciones de GitHub Actions |
| [Azure Updates](https://azure.microsoft.com/updates/) | Retiros y GA de servicios de Azure |
| [AKS release tracker](https://releases.aks.azure.com/) y [blog de AKS](https://blog.aks.azure.com/) | Versiones y cambios de AKS |
| [.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core) · [Node.js releases](https://nodejs.org/en/about/previous-releases) · [endoflife.date](https://endoflife.date/) | Ciclos de vida de runtimes |
| [AzureRM CHANGELOG](https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md) · [Bicep releases](https://github.com/Azure/bicep/releases) | Cambios de IaC |

[← Glosario](12-glosario.md) · [Índice](../README.md)
