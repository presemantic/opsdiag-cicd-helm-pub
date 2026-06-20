# charts-public

Public Helm charts for OpsDiag.

## Charts

- [`opsolving/opsdiag-connector`](./opsolving/opsdiag-connector) deploys the customer-side OpsDiag gateway connector and depends only on the Opsolving `common` library chart.

## OCI install

```bash
helm install opsdiag-connector \
  oci://europe-west1-docker.pkg.dev/prod-common-cicd/charts-public/opsolving/opsdiag-connector \
  --version 0.1.0
```
