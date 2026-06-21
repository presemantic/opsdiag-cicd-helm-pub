# OpsDiag Charts Instructions

## Purpose

This project is `opsdiag-charts`: the public Helm chart repository for OpsDiag deployable artifacts.

## Structure

- [`opsdiag-app-connector/`](./opsdiag-app-connector/) contains the public Helm chart for the customer-side OpsDiag app connector.
- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages public charts on timestamp release tags and pushes them to Artifact Registry as Helm OCI artifacts.
- Chart dependencies must use the Opsolving public chart repository and depend only on `common` from `https://github.com/opsolving/charts/tree/main/opsolving/common`.
- [`README.md`](./README.md) documents the public chart repository contents.

## Constraints

Keep chart values honest: every value added to `values.yaml` must be consumed by templates or documented as a global value consumed by the common library helpers. Do not add placeholder values that are never rendered.

Use the Bitnami-style pattern where application templates stay thin and reuse the `common` library for names, labels, image rendering, pull secrets, templated values, resources, and affinity helpers.

Do not vendor dependency charts into this repository unless explicitly requested. Dependency resolution should use Helm dependency commands against `https://opsolving.github.io/charts/`.

Chart release workflows must publish Helm OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/charts-opsdiag`. The `charts-opsdiag` Artifact Registry repository must be an OCI/Docker-compatible repository for `helm push` and `helm install oci://...` workflows.

Charts are pushed directly to the dedicated OpsDiag chart repository without an extra namespace segment. For example, `opsdiag-app-connector` is pushed as `europe-west1-docker.pkg.dev/prod-common-cicd/charts-opsdiag/opsdiag-app-connector`.

The public connector chart must not expose or inject the Control gateway-token endpoint. The connector binary owns that production default; the chart only supplies the license secret, relay WebSocket URL, and runtime tuning values.

The connector chart `appVersion` and default image tag track the released `opsdiag-app-connector` image tag. The release workflow must not rewrite `appVersion` to the chart release tag.

The chart release workflow must not require `presemantic/actions-helpers` or `GH_ACTIONS_HELPERS_TOKEN`; it resolves timestamp release tags directly from the triggering GitHub ref.
