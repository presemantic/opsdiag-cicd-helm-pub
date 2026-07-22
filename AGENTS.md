# OpsDiag Charts Instructions

## Purpose

This project is `opsdiag-cicd-helm-pub`, the public Helm chart repository for customer-deployable OpsDiag artifacts. It publishes one unified `opsdiag-app` chart for the complete application stack and one independent `opsdiag-app-connector` chart for customer-side relay connectivity.

## Structure

- [`opsdiag-app/`](./opsdiag-app/) deploys App API, App Agent, App Front, App Scheduler, the thin App MCP Proxy, and App VCS from `api`, `agent`, `front`, `sched`, `mcp-proxy`, and `vcs`. It also owns optional Kubernetes Ingress, OpenShift Route, Istio Gateway, and Istio VirtualService resources.
- [`opsdiag-app-connector/`](./opsdiag-app-connector/) remains an independent chart because the connector is installed separately in customer environments.

The current unified App chart source version is `0.1.27` with `appVersion` `2026-07-22`. It includes the mandatory authenticated MCP Proxy, OAuth/OIDC discovery and `/mcp/oauth/*` authorization routing, `/mcp` exposure while reserving `/oauth` for App UI login, and the App VCS webhook route. App Agent is pinned to `2026-07-22.04-44-35.d3ab73f`, whose review tools use OpenAI-compatible strict object schemas with every property explicitly required and optional values represented as nullable. App API is pinned to `2026-07-22.09-34-46.2f06810`, which keeps review runs webhook-driven and removes the manual retry route. App Front is pinned to `2026-07-22.09-34-16.0568098`, which keeps reviewer definitions in Config and renders review history under tenant Analyses. App VCS is pinned to exact release `2026-07-22.03-32-43.7fa4b5b`, which resolves provider access tokens from Secret-backed environment variables when credentials use `accessTokenEnv`. Chart version changes do not authorize invented component image tags, and production deployment values must continue to avoid image overrides.

The current independent Connector chart source version is `0.2.3` with `appVersion` `2026-07-20.19-03-10.84c320e`. It uses the exact published Connector image that starts an overlapping replacement Relay session six minutes before grant expiry, drains existing five-minute actions on the previous session and ignores only late frames for recently closed known stream IDs instead of reconnecting the entire session; do not replace it with a locally rebuilt binary or an unpublished tag.

- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages both public charts on timestamp release tags and publishes them as OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/opsdiag-helm-pub`.

## Chart Design

Use the Bitnami-style component hierarchy in `values.yaml`. App API, App Agent, App Front, App Scheduler, App MCP Proxy, and App VCS are mandatory parts of the unified release and must always render; do not expose per-component `enabled` switches. Each component owns its replicas, image, service account, pod configuration, service, probes, resources, scheduling, disruption budget, and runtime config. Component image registry, repository, tag, digest, and pull policy defaults belong to the chart; production values must not override them. The unified chart `appVersion` is suite metadata, while the exact released image is pinned independently under each component's `image.tag`.

The public `values.yaml` is also the chart's parameter reference. Keep it organized in Bitnami-style `## @section` blocks, document every supported public value with an adjacent `## @param` description, separate major runtime, image, security, networking, resource, probe, scheduling, migration, and exposure groups with whitespace, and include concise commented examples for structured lists such as Ingress rules. Documentation-only formatting must preserve the rendered value tree exactly.

Stable application defaults such as health probes, component runtime behavior, service ports, security contexts, rollout strategies, Control/Relay origins, scheduler wiring, migration retry behavior, and the API disruption budget belong in the chart and must not be repeated in environment values. Official component images do not expose Helm `command`, `args`, or `resourcesPreset` overrides; migration uses its fixed binary command and every workload accepts only explicit `resources`. App API always mounts and reads `/app/config.yaml`, and scheduler integration is mandatory rather than feature-gated. The single-replica Agent uses a no-surge rolling replacement (`maxSurge: 0`, `maxUnavailable: 1`) as its chart-owned default. Deployment repositories explicitly own production replica counts and resources together with settings that genuinely vary by environment or customer, such as credentials, licenses, provider targets, model profiles, database endpoints, migration acknowledgements, Go runtime sizing, exposure, and exceptional rollout constraints.

Internal App API, Agent, Scheduler, MCP Proxy, and VCS upstream URLs must be rendered from `opsdiag-app.componentName` and the selected component service port. Never hardcode the default `opsdiag-app-*` release names in runtime environment variables or generated component configuration. The generated URLs must follow the actual Helm release name and support both `nameOverride` and `fullnameOverride`.

Application exposure keeps the application topology private to the chart. Kubernetes Ingress, OpenShift Route, and Istio values expose only platform-facing hostname, class or gateway selector, annotations, and TLS settings, plus explicitly named `extra*` extension lists. The chart always owns OAuth protected-resource discovery to App MCP Proxy, OAuth/OIDC authorization-server discovery and `/mcp/oauth` to App API, `/mcp` to App MCP Proxy, `/api/vcs/hooks` to App VCS, `/api` to App API, and `/` to App Frontend in that precedence order; `/oauth` is reserved for App UI login and follows the frontend route. It also owns component Service names and ports. Exposure values must not accept primary `rules`, mutable primary paths, backend component selectors, backend ports, arbitrary resource `name`, per-resource `fullnameOverride`, or `items` wrappers. Every exposure resource name and every primary component backend reference must be generated from the Helm release and chart-level naming overrides.

Kubernetes Ingress uses `ImplementationSpecific` only for the chart-owned `/.well-known/*` discovery paths because ingress-nginx strict path admission rejects dots with `Exact` or `Prefix`; the paths remain literal because the chart does not enable regex routing. Ordinary `/mcp/oauth`, `/mcp`, `/api`, and `/` paths keep their semantic Prefix routing.

Application templates must remain thin and reuse the Opsolving `common` library from `https://opsolving.github.io/charts/` for names, labels, images, pull secrets, templated values, resources, and affinity helpers. Do not vendor dependencies unless explicitly requested. Every value must be consumed by a template or be an intentional global common-library value. Preserve stable workload and service names during chart refactors so GitOps adoption does not recreate immutable resources.

The App API, App Agent, App Scheduler, App MCP Proxy, and App VCS runtime YAML is rendered from their component `config` blocks into component-specific Kubernetes Secrets mounted read-only at `/app/config.yaml`; licenses, credentials, webhook key material, JWT material, model secrets, and worker tokens therefore never enter ConfigMaps. App Front does not receive a fake runtime config. `global.externalURL` is the single canonical OAuth issuer; the chart renders it into App API and MCP Proxy config and renders all internal App service URLs from release-aware service names.

## Connector Constraints

The connector chart renders `/app/config.yaml` from top-level `config`. Its standard license and Control Edge URL live directly under `config`; relay license, WebSocket URL, `connectTimeoutSeconds`, and `maxFrameBytes` live under `config.relay`. Do not duplicate the Control Edge URL, include derived `/api/...` paths, project these values through environment variables, or restore a separate top-level connector section.

The connector must remain compatible with OpenShift restricted SCC. Do not set fixed `runAsUser`, `runAsGroup`, or `fsGroup` defaults. Keep non-root execution, no privilege escalation, a read-only root filesystem, dropped capabilities, and RuntimeDefault seccomp.

## Release Constraints

Chart dependencies must use only the public Opsolving `common` dependency. The release workflow must resolve timestamp tags directly from the Git ref, must not depend on `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`, and must not rewrite component image tags or chart `appVersion` during packaging.

Product documentation belongs in `opsdiag-docs-ai-context`, not this repository. Keep public chart defaults free of tenant credentials, endpoints, licenses, or environment-specific values.

The breaking gateway transport release is unified App chart `0.1.7` plus customer Connector chart `0.2.0`; unified App chart `0.1.8` is the frontend security-header hotfix and `0.1.9` adds continuous encrypted gateway-grant readiness monitoring to the Agent. Public workloads do not expose container command/args, component-specific extra volumes/mounts, or component-specific `extraDeploy`; only top-level unified-chart `extraDeploy` remains. `extraEnvVars`, `extraEnvVarsCM`, and `extraEnvVarsSecret` remain supported. Front always renders chart-owned `emptyDir` mounts for Nginx runtime paths and defaults to a read-only root filesystem.
