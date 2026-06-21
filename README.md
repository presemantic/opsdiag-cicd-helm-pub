# opsdiag-charts

Public Helm charts for OpsDiag.

## Charts

- [`opsdiag-app-connector`](./opsdiag-app-connector) deploys the customer-side OpsDiag app connector and depends only on the Opsolving `common` library chart.

## OCI install

```bash
helm install opsdiag-app-connector \
  oci://europe-west1-docker.pkg.dev/prod-common-cicd/charts-opsdiag/opsdiag-app-connector \
  --version 0.1.2
```
