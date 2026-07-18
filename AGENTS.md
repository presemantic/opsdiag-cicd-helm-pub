# OpsDiag Charts Instructions

## Purpose

This project is `opsdiag-cicd-helm-pub`, the public Helm chart repository for customer-deployable OpsDiag artifacts. It publishes one unified `opsdiag-app` chart for the complete application stack and one independent `opsdiag-app-connector` chart for customer-side relay connectivity.

## Structure

- [`opsdiag-app/`](./opsdiag-app/) deploys App API, App Agent, App Front, and App Scheduler from the component sections `api`, `agent`, `front`, and `sched`. It also owns optional Kubernetes Ingress, OpenShift Route, Istio Gateway, and Istio VirtualService resources.
- [`opsdiag-app-connector/`](./opsdiag-app-connector/) remains an independent chart because the connector is installed separately in customer environments.
- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages both public charts on timestamp release tags and publishes them as OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/opsdiag-helm-pub`.

## Chart Design

Use the Bitnami-style component hierarchy in `values.yaml`. Each component owns its replicas, image, service account, pod configuration, service, probes, resources, scheduling, disruption budget, and runtime config. Component image registry, repository, tag, digest, and pull policy defaults belong to the chart; production values must not override them. The unified chart `appVersion` is suite metadata, while the exact released image is pinned independently under each component's `image.tag`.

Stable application defaults such as replica counts, health probes, component runtime behavior, service ports, security contexts, and the API disruption budget belong in the chart and must not be repeated in environment values. Deployment repositories should override only settings that genuinely vary by environment or customer, such as credentials, licenses, provider targets, model profiles, feature flags, database endpoints, resource sizing, exposure, and exceptional rollout constraints.

Internal App API, Agent, and Scheduler URLs must be rendered from `opsdiag-app.componentName` and the selected component service port. Never hardcode the default `opsdiag-app-*` release names in runtime environment variables or generated component configuration. The generated URLs must follow the actual Helm release name and support both `nameOverride` and `fullnameOverride`.

Application templates must remain thin and reuse the Opsolving `common` library from `https://opsolving.github.io/charts/` for names, labels, images, pull secrets, templated values, resources, and affinity helpers. Do not vendor dependencies unless explicitly requested. Every value must be consumed by a template or be an intentional global common-library value. Preserve stable workload and service names during chart refactors so GitOps adoption does not recreate immutable resources.

The App API and App Agent runtime YAML is rendered from `api.config` and `agent.config` into ConfigMaps. App Scheduler runtime YAML, including provider credentials, is rendered from `sched.config` into a Secret and mounted read-only. App Front does not receive a fake runtime config. The scheduler worker token must use `api.schedulerWorkerToken.value` or `api.schedulerWorkerToken.existingSecret`; it must not enter the API ConfigMap.

## Connector Constraints

The connector chart renders `/app/config.yaml` from top-level `config`. Its standard license and Control Edge URL live directly under `config`; relay license, WebSocket URL, `connectTimeoutSeconds`, and `maxFrameBytes` live under `config.relay`. Do not duplicate the Control Edge URL, include derived `/api/...` paths, project these values through environment variables, or restore a separate top-level connector section.

The connector must remain compatible with OpenShift restricted SCC. Do not set fixed `runAsUser`, `runAsGroup`, or `fsGroup` defaults. Keep non-root execution, no privilege escalation, a read-only root filesystem, dropped capabilities, and RuntimeDefault seccomp.

## Release Constraints

Chart dependencies must use only the public Opsolving `common` dependency. The release workflow must resolve timestamp tags directly from the Git ref, must not depend on `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`, and must not rewrite component image tags or chart `appVersion` during packaging.

Product documentation belongs in `opsdiag-docs-ai-context`, not this repository. Keep public chart defaults free of tenant credentials, endpoints, licenses, or environment-specific values.
