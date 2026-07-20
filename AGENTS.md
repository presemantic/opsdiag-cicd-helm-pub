# OpsDiag Charts Instructions

## Purpose

This project is `opsdiag-cicd-helm-pub`, the public Helm chart repository for customer-deployable OpsDiag artifacts. It publishes one unified `opsdiag-app` chart for the complete application stack and one independent `opsdiag-app-connector` chart for customer-side relay connectivity.

## Structure

- [`opsdiag-app/`](./opsdiag-app/) deploys App API, App Agent, App Front, and App Scheduler from the component sections `api`, `agent`, `front`, and `sched`. It also owns optional Kubernetes Ingress, OpenShift Route, Istio Gateway, and Istio VirtualService resources.
- [`opsdiag-app-connector/`](./opsdiag-app-connector/) remains an independent chart because the connector is installed separately in customer environments.

The current unified App chart source version is `0.1.13` with `appVersion` `2026-07-20`. Chart version changes do not authorize invented component image tags: component defaults must move only to exact images that were actually released, and production deployment values must continue to avoid image overrides. Version `0.1.13` advances only App Front with the full-height Knowledge Builder editor layout; App API, App Agent, and App Scheduler stay on their existing compatible images.

The current independent Connector chart source version is `0.2.1` with `appVersion` `2026-07-20.03-01-32.d7eb341`. It uses the exact published and proof-version-2-attested Connector image that refreshes its outbound Relay session before the gateway JWT and signed descriptor expire; do not replace it with a locally rebuilt binary or an unpublished tag.

- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages both public charts on timestamp release tags and publishes them as OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/opsdiag-helm-pub`.

## Chart Design

Use the Bitnami-style component hierarchy in `values.yaml`. App API, App Agent, App Front, and App Scheduler are mandatory parts of the unified release and must always render; do not expose per-component `enabled` switches. Each component owns its replicas, image, service account, pod configuration, service, probes, resources, scheduling, disruption budget, and runtime config. Component image registry, repository, tag, digest, and pull policy defaults belong to the chart; production values must not override them. The unified chart `appVersion` is suite metadata, while the exact released image is pinned independently under each component's `image.tag`.

The public `values.yaml` is also the chart's parameter reference. Keep it organized in Bitnami-style `## @section` blocks, document every supported public value with an adjacent `## @param` description, separate major runtime, image, security, networking, resource, probe, scheduling, migration, and exposure groups with whitespace, and include concise commented examples for structured lists such as Ingress rules. Documentation-only formatting must preserve the rendered value tree exactly.

Stable application defaults such as health probes, component runtime behavior, service ports, security contexts, rollout strategies, Control/Relay origins, scheduler wiring, migration retry behavior, and the API disruption budget belong in the chart and must not be repeated in environment values. Official component images do not expose Helm `command`, `args`, or `resourcesPreset` overrides; migration uses its fixed binary command and every workload accepts only explicit `resources`. App API always mounts and reads `/app/config.yaml`, and scheduler integration is mandatory rather than feature-gated. The single-replica Agent uses a no-surge rolling replacement (`maxSurge: 0`, `maxUnavailable: 1`) as its chart-owned default. Deployment repositories explicitly own production replica counts and resources together with settings that genuinely vary by environment or customer, such as credentials, licenses, provider targets, model profiles, database endpoints, migration acknowledgements, Go runtime sizing, exposure, and exceptional rollout constraints.

Internal App API, Agent, and Scheduler URLs must be rendered from `opsdiag-app.componentName` and the selected component service port. Never hardcode the default `opsdiag-app-*` release names in runtime environment variables or generated component configuration. The generated URLs must follow the actual Helm release name and support both `nameOverride` and `fullnameOverride`.

Application exposure keeps the application topology private to the chart. Kubernetes Ingress, OpenShift Route, and Istio values expose only platform-facing hostname, class or gateway selector, annotations, and TLS settings, plus explicitly named `extra*` extension lists. The chart always owns the primary `/api` to App API and `/` to App Frontend paths, component Service names, and Service ports. Exposure values must not accept primary `rules`, mutable primary paths, backend component selectors, backend ports, arbitrary resource `name`, per-resource `fullnameOverride`, or `items` wrappers. Every exposure resource name and every primary component backend reference must be generated from the Helm release and the chart-level `nameOverride` or `fullnameOverride`.

Application templates must remain thin and reuse the Opsolving `common` library from `https://opsolving.github.io/charts/` for names, labels, images, pull secrets, templated values, resources, and affinity helpers. Do not vendor dependencies unless explicitly requested. Every value must be consumed by a template or be an intentional global common-library value. Preserve stable workload and service names during chart refactors so GitOps adoption does not recreate immutable resources.

The App API, App Agent, and App Scheduler runtime YAML is rendered from `api.config`, `agent.config`, and `sched.config` into component-specific Kubernetes Secrets and mounted read-only at `/app/config.yaml`; database URLs, licenses, credentials, JWT material, model secrets, and the shared scheduler worker token therefore never enter ConfigMaps or ordinary environment values. App Front does not receive a fake runtime config. Internal API, Agent, Scheduler, and callback URLs are chart-rendered config values derived from release-aware service names.

## Connector Constraints

The connector chart renders `/app/config.yaml` from top-level `config`. Its standard license and Control Edge URL live directly under `config`; relay license, WebSocket URL, `connectTimeoutSeconds`, and `maxFrameBytes` live under `config.relay`. Do not duplicate the Control Edge URL, include derived `/api/...` paths, project these values through environment variables, or restore a separate top-level connector section.

The connector must remain compatible with OpenShift restricted SCC. Do not set fixed `runAsUser`, `runAsGroup`, or `fsGroup` defaults. Keep non-root execution, no privilege escalation, a read-only root filesystem, dropped capabilities, and RuntimeDefault seccomp.

## Release Constraints

Chart dependencies must use only the public Opsolving `common` dependency. The release workflow must resolve timestamp tags directly from the Git ref, must not depend on `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`, and must not rewrite component image tags or chart `appVersion` during packaging.

Product documentation belongs in `opsdiag-docs-ai-context`, not this repository. Keep public chart defaults free of tenant credentials, endpoints, licenses, or environment-specific values.

The breaking gateway transport release is unified App chart `0.1.7` plus customer Connector chart `0.2.0`; unified App chart `0.1.8` is the frontend security-header hotfix and `0.1.9` adds continuous encrypted gateway-grant readiness monitoring to the Agent. Public workloads do not expose container command/args, component-specific extra volumes/mounts, or component-specific `extraDeploy`; only top-level unified-chart `extraDeploy` remains. `extraEnvVars`, `extraEnvVarsCM`, and `extraEnvVarsSecret` remain supported. Front always renders chart-owned `emptyDir` mounts for Nginx runtime paths and defaults to a read-only root filesystem.
