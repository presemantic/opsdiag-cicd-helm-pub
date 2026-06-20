# OpsDiag Public Charts Instructions

## Purpose

This project is `charts-public`: the public Helm chart repository for OpsDiag deployable artifacts.

## Structure

- [`opsolving/opsdiag-connector/`](./opsolving/opsdiag-connector/) contains the public Helm chart for the customer-side OpsDiag gateway connector.
- [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) packages public charts on timestamp release tags and pushes them to Artifact Registry as Helm OCI artifacts.
- Chart dependencies must use the Opsolving public chart repository and depend only on `common` from `https://github.com/opsolving/charts/tree/main/opsolving/common`.
- [`README.md`](./README.md) documents the public chart repository contents.

## Constraints

Keep chart values honest: every value added to `values.yaml` must be consumed by templates or documented as a global value consumed by the common library helpers. Do not add placeholder values that are never rendered.

Use the Bitnami-style pattern where application templates stay thin and reuse the `common` library for names, labels, image rendering, pull secrets, templated values, resources, and affinity helpers.

Do not vendor dependency charts into this repository unless explicitly requested. Dependency resolution should use Helm dependency commands against `https://opsolving.github.io/charts/`.

Chart release workflows must publish Helm OCI artifacts to `europe-west1-docker.pkg.dev/prod-common-cicd/charts-public`. The `charts-public` Artifact Registry repository must be an OCI/Docker-compatible repository for `helm push` and `helm install oci://...` workflows.
