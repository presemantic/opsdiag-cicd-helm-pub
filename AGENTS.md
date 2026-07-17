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

Chart `opsdiag-app-front` `0.1.3` selects the frontend release that replaces missing, invalid, or overlapping flow coordinates with a neutral DAG layout so historical damaged Template copies remain usable.

Chart `opsdiag-app-agent` `0.1.4` selects the App Agent release with connector-routed OKD/OpenShift discovery and diagnostics. Cluster API servers remain access-scoped runtime configuration and bearer credentials remain in named App Agent credentials rather than chart defaults.

Chart `opsdiag-app-agent` `0.1.5` selects the App Agent release with 46 strict connector-routed Artifactory/Xray read-only tools, bounded queries, secret-shaped response redaction, and the verified LPP live-smoke behavior. Platform origins and authentication remain named App Agent credentials rather than chart defaults.

Chart `opsdiag-app-agent` `0.1.6` selects the App Agent release with 67 strict connector-routed PMM tools over the Grafana datasource proxy and Prometheus-compatible endpoints. Named PMM instances, bearer tokens, datasource identifiers, and TLS settings remain App Agent configuration rather than chart defaults.

Chart `opsdiag-app-api` `0.1.3` selects the App API release with deterministic artifact evidence IDs, idempotent checkpoint acknowledgements, and scoped byte-bounded evidence paging for private chat runs.

Chart `opsdiag-app-agent` `0.1.8` selects the adaptive MCP evidence release. It preserves complete private artifacts, sends compact structurally valid model projections, segments safe seven-day temporal queries, uses the PMM Grafana `/graph` base and target datasource identity, and propagates per-target insecure TLS intent through the authenticated Relay for configured PMM and OKD endpoints.

Chart `opsdiag-app-agent` `0.1.9` selects the fail-closed, connector-routed Argo CD and GitHub Actions diagnostics release. Both providers expose only fixed read-only tool catalogs, enforce configured scope and bounded pagination/log retrieval, and redact credential-shaped content.

Chart `opsdiag-app-agent` `0.1.10` selects the proxy-safe Argo CD cluster lookup release. `get_cluster` uses Argo CD's exact server query selector and verifies the returned server locally, avoiding route ambiguity when a Kubernetes API URL contains reserved path characters.

Chart `opsdiag-app-api` `0.1.4` exposes GitHub Actions as a read-only SDLC provider agent while keeping legacy Template RCA layout validation independent from later catalog additions.

Chart `opsdiag-app-agent` `0.1.11` selects the scheduled-scope evidence release used by Scheduler v2 and includes the connector-routed Datadog managed MCP integration. Scheduled evidence references remain scoped to the run and downstream nodes receive only the evidence allowed by the immutable execution snapshot.

Chart `opsdiag-app-agent` `0.1.12` selects the same Scheduler v2 and Datadog functionality from exact pushed image `2026-07-17.02-31-45.db901b7`, whose shipped binary is attested after the registry push.

Chart `opsdiag-app-api` `0.1.5` selects Scheduler v2 API image `2026-07-17.02-26-49.f5e79bf` and moves scheduler-worker authentication out of the rendered ConfigMap into a chart-managed or externally supplied Kubernetes Secret.

Chart `opsdiag-app-api` `0.1.6` selects the exact final Scheduler v2 API image `2026-07-17.03-13-23.6184e68`, including the corrected binary-attestation secret scan and the durable scheduler execution/continuation API used after migration `030_scheduler_execution.sql`.

Chart `opsdiag-app-api` `0.1.7` selects Scheduler v2 API image `2026-07-17.10-19-08.00ef0a7`, which pins the poll-advance timestamp parameter to PostgreSQL `timestamptz` so due schedules can be claimed and `next_poll_at` advances at the configured cadence.

Chart `opsdiag-app-api` `0.1.8` selects Scheduler v2 API image `2026-07-17.10-50-32.0a9d689`, which normalizes poll-end watermarks to PostgreSQL microsecond precision so valid completed polls are not rejected after a database round-trip.

Chart `opsdiag-app-front` `0.1.4` selects the Scheduler v2 frontend with explicit flow selection, provider-specific Opsgenie/PagerDuty fields, scheduled run history, and private `Continue in Chat` continuity.

Chart `opsdiag-app-api` `0.1.9` separates scheduler-bound flows from ordinary chat selection, permits explicit private continuation of terminal scheduled runs, and uses the same flat provider-access scope fingerprint as App Agent. Migration `031_scheduler_chat_separation.sql` is additive and extends continuation idempotency to the caller-supplied continuation ID.

Chart `opsdiag-app-front` `0.1.5` hides scheduler-only flows from normal chat creation and makes every explicit `Continue in Chat` action create and load its own private continuation without exposing the scheduler flow as a chat choice.

Chart `opsdiag-app-api` `0.1.10` restores the pinned flow scope before scheduled node-context validation, exposes response availability, and permits `Continue in Chat` only when the run produced a real model response.

Chart `opsdiag-app-api` `0.1.11` selects the corrected scheduled node-memory checkpoint release, which loads the immutable flow scope from the tenant-scoped scheduled-run row before persisting the final response context.

Chart `opsdiag-app-front` `0.1.6` separates scheduled responses from execution errors, prevents response-less runs from creating chats, and keeps scheduler-only pinned flow snapshots usable for follow-up messages in explicit continuations.

The connector chart must stay compatible with OpenShift restricted SCC. Do not set fixed `runAsUser`, `runAsGroup`, or `fsGroup` defaults; OpenShift injects a namespace-range random UID. Keep non-root, no privilege escalation, read-only root filesystem, dropped capabilities, and RuntimeDefault seccomp defaults.

The chart release workflow must not require `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`; it resolves timestamp release tags directly from the triggering GitHub ref.

## App Scheduler Configuration

The public `opsdiag-app-sched` chart renders the complete scheduler runtime config into a Kubernetes `Secret`, mounts it read-only at `/app/config.yaml`, and rolls the Deployment when that secret content changes. Provider credentials must never move to a ConfigMap, App API values, frontend state, or database seed. Compatibility releases that retain the legacy image must keep both probes on `/api/health`; `/api/live` and `/api/ready` may be selected only in the same chart release that selects a Scheduler v2 image implementing those endpoints.

The App API scheduler worker token must not be included in `config`, because that value is rendered into the App API ConfigMap. Supply it through `schedulerWorkerToken.value` for a chart-managed Kubernetes Secret or through `schedulerWorkerToken.existingSecret`; the Deployment consumes only the referenced Secret key as `APP_SCHEDULER_WORKER_TOKEN`.

Chart `opsdiag-app-sched` `0.1.4` is the corrected scheduler v2 phase-one compatibility release: it keeps the Secret-backed runtime configuration introduced in `0.1.3`, restores the legacy image's `/api/health` probes, and intentionally retains the existing scheduler `appVersion` and default image tag. A later chart release may select the Scheduler v2 image and its split live/ready probes only after this secret-backed configuration is installed.

Chart `opsdiag-app-sched` `0.1.5` selects Scheduler v2 image `2026-07-17.02-14-07.190b8d9`, uses `/api/live` for liveness and `/api/ready` for readiness, and gives readiness enough timeout for its bounded App API dependency check.

Chart `opsdiag-app-sched` `0.1.6` selects exact pushed image `2026-07-17.02-45-22.a4770dd` with the split live/ready probes, the PagerDuty EU endpoint fix, and post-push binary attestation.
