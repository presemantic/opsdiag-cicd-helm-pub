# Third-party notices for opsdiag-app

The `opsdiag-app` chart redistributes the official Apache APISIX Helm chart and deploys the Apache APISIX container image.

- Project: Apache APISIX
- Helm chart: `apisix` 2.16.0
- Application: Apache APISIX 3.17.0
- Source: https://github.com/apache/apisix-helm-chart
- License: Apache License 2.0; see [`APISIX-LICENSE.txt`](./APISIX-LICENSE.txt)
- Notice: see [`APISIX-NOTICE.txt`](./APISIX-NOTICE.txt)

OpsDiag does not modify the Apache APISIX source distribution. OpsDiag supplies product-specific standalone routing through a generated `apisix.yaml` mounted into the official chart workload.
