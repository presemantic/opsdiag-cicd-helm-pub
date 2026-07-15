# OpsDiag Charts Instructions

## Purpose

This project is `opsdiag-cicd-helm-pub`: the public Helm chart repository for OpsDiag deployable artifacts.

## Structure

- [`opsdiag-app-front/`](./opsdiag-app-front/) contains the public Helm chart for the OpsDiag app frontend.
- [`opsdiag-app-api/`](./opsdiag-app-api/) contains the public Helm chart for the OpsDiag app API, including its optional migration Job.
- [`opsdiag-app-agent/`](./opsdiag-app-agent/) contains the public Helm chart for the single multi-role OpsDiag app-agent runtime.
- [`opsdiag-app-sched/`](./opsdiag-app-sched/) contains the public Helm chart for the OpsDiag app scheduler.
- [`opsdiag-app-connector/`](./opsdiag-app-connector/) contains the public Helm chart for the customer-side OpsDiag app connector.
- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages every public chart on timestamp release tags and pushes them to Artifact Registry as Helm OCI artifacts.
- Chart dependencies must use the Opsolving public chart repository and depend only on `common` from `https://github.com/opsolving/charts/tree/main/opsolving/common`.

## Constraints

Product documentation must live in `opsdiag-docs-ai-context`, not in per-repository overview docs.

Keep chart values honest: every value added to `values.yaml` must be consumed by templates or documented as a global value consumed by the common library helpers. Do not add placeholder values that are never rendered.

Use the Bitnami-style pattern where application templates stay thin and reuse the `common` library for names, labels, image rendering, pull secrets, templated values, resources, and affinity helpers.

Do not vendor dependency charts into this repository unless explicitly requested. Dependency resolution should use Helm dependency commands against `https://opsolving.github.io/charts/`.

Chart release workflows must publish Helm OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/opsdiag-helm-pub`. The `opsdiag-helm-pub` Artifact Registry repository must be an OCI/Docker-compatible repository for `helm push` and `helm install oci://...` workflows.

Charts are pushed directly to the dedicated public OpsDiag chart repository without an extra namespace segment. For example, `opsdiag-app-connector` is pushed as `europe-west1-docker.pkg.dev/prod-common-cicd/opsdiag-helm-pub/opsdiag-app-connector`.

The public connector chart renders `/app/config.yaml` from the top-level `config` value. Standard `license` and base Control edge `url` must live at the top level of `config`, while relay settings must live under `config.relay` as `license`, relay WebSocket `url`, `connectTimeoutSeconds`, and `maxFrameBytes` in deploy/user values, not in the public chart defaults. Do not duplicate the Control edge URL under `config.relay`, include `/api/...` paths in config URLs, project these fields through environment variables, or reintroduce a separate top-level `connector` values section.

The public app backend charts render `/app/config.yaml` from the top-level `config` value and expose a ClusterIP service on port 8000. The frontend chart serves nginx on port 3000 and must not grow a fake config file unless the frontend image starts reading one. The `opsdiag-app-agent` chart deploys one scalable multi-role service with `runtime.agentKind=root`; do not reintroduce per-agent or per-provider Helm releases unless a future design explicitly restores that runtime model.

The connector chart `appVersion` and default image tag track the released `opsdiag-app-connector` image tag. The release workflow must not rewrite `appVersion` to the chart release tag.

The same image ownership rule applies to every public application chart: `Chart.yaml` `appVersion` and the default `values.yaml` `image.tag` must be identical to the released component image, and changing that image requires a chart version bump. Deployment values must not compensate for stale chart metadata with an `image.tag` override.

Chart `opsdiag-app-agent` `0.1.4` selects the App Agent release with connector-routed OKD/OpenShift discovery and diagnostics. Cluster API servers remain access-scoped runtime configuration and bearer credentials remain in named App Agent credentials rather than chart defaults.

The connector chart must stay compatible with OpenShift restricted SCC. Do not set fixed `runAsUser`, `runAsGroup`, or `fsGroup` defaults; OpenShift injects a namespace-range random UID. Keep non-root, no privilege escalation, read-only root filesystem, dropped capabilities, and RuntimeDefault seccomp defaults.

The chart release workflow must not require `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`; it resolves timestamp release tags directly from the triggering GitHub ref.
