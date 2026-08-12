# Opsolving Public Charts Instructions

## Purpose

This repository publishes customer-deployable Opsolving charts. [`opsolving-app/`](./opsolving-app/) is the unified application stack, and [`opsolving-app-connector/`](./opsolving-app-connector/) is the separately installed customer connector. Release CI publishes public OCI charts below `europe-docker.pkg.dev/presemantic/public/charts`; customer-deployable component images live below the sibling `images` path in the same public repository.

## Structure

[`opsolving-app/`](./opsolving-app/) owns API, Agent, Front, Scheduler, Pipelines, MCP Proxy, VCS, mandatory standalone APISIX, and independent `pgsql` and `pgsql-tables` PostgreSQL 18 instances. The embedded databases use the Docker Official `postgres:18` image and direct chart-owned Secret, ServiceAccount, Service, headless Service, StatefulSet, and PVC templates. Either database may be disabled only when the matching explicit external URL is supplied. [`opsolving-app-connector/`](./opsolving-app-connector/) owns the separately released Connector workload and its Secret-backed runtime configuration.

## Chart Design

Both charts follow the Opsolving Bitnami-style contract and use the Opsolving `common` library from `https://opsolving.github.io/charts/`. Keep one readable Kubernetes object per template. Helpers may calculate chart-specific names and scalar values, but must not render complete resources, resources blocks, affinity blocks, arbitrary objects, or copied/mutated value trees. Generic `extraDeploy`, PodDisruptionBudget, and NetworkPolicy resources are intentionally unsupported.

Values are the public parameter reference. Keep `## @section` and adjacent `## @param` documentation complete, preserve structured component roots, and keep component image defaults in the chart. The App suite `appVersion` is release metadata; Connector `appVersion` must equal its default image tag. Dependencies remain pinned by `Chart.lock` and committed vendor archives so linting and packaging do not fetch at release time.

## Application Contract

APISIX is the only application-routing authority. It runs as a two-or-more-replica standalone data-plane Deployment with etcd, Admin API, Control API, dashboard, ingress controller, CRDs, Gateway API, metrics Service, and stream listeners disabled. Parent-generated `apisix.yaml` owns OAuth discovery, `/mcp/oauth`, `/mcp/proxy`, `/mcp/self`, VCS hooks, API, and Front routes. Kubernetes Ingress, OpenShift Route, and Istio expose only hostname, TLS, and one `/` route to APISIX.

Runtime configuration containing credentials is rendered to component-specific Secrets mounted read-only at `/app/config.yaml`. VCS and Scheduler credentials are inline config entries referenced by name from their `sources`; static Scheduler and Pipelines worker tokens are unsupported, and their internal calls use request-bound license capabilities. App API, migration, and Pipelines must use the same chart-derived main and Tables database URLs. Embedded URLs use `sslmode=disable`; explicit external URLs retain their configured TLS mode. PostgreSQL resources run in Argo wave `-20`, migration dependencies in wave `-11`, and the blocking migration Job in wave `-10`.

Connector-backed egress is disabled by default for every App component. An environment that installs the standalone Connector must explicitly set each participating component's `config.connector.enabled` value and its environment-specific Relay URL; the chart must not infer Connector usage from nested source or credential fields. Customer-facing defaults use `https://edge.opsolving.ai` for license verification and Connector grants and `https://relay.opsolving.ai` for Connector client transport.

## Compatibility

The product and Kubernetes resource brand is Opsolving. Historical wire identifiers such as `X-OpsDiag-*`, `OpsDiag-Payload`, persisted export formats, license component IDs, and Go module paths remain unchanged until a separately versioned protocol migration is implemented. Do not rename them as part of visual or deployment rebranding.

The intentional production rebrand uses new `opsolving-*` releases, StatefulSets, and PVCs. The separate Control PostgreSQL installation is not part of this chart and must never be renamed, recreated, migrated, or removed by App chart work.

## Validation

Run `helm lint` and `helm template` for both charts, render the App chart with [`ci-values.yaml`](./opsolving-app/ci-values.yaml), verify selectors against pod labels, and reject rendered PDB or NetworkPolicy objects. Verify exactly two chart-owned PostgreSQL StatefulSets, official `postgres:18`, stable client Services, `-v18` StatefulSet names, and the APISIX standalone configuration.

Do not run Helm install, upgrade, rollback, or cluster mutations unless the user explicitly authorizes deployment. Before publishing, inspect the diff and status, preserve the current branch, and use the repository's timestamp/hash release-tag convention.
