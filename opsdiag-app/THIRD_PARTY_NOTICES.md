# Third-party notices for opsdiag-app

The `opsdiag-app` chart redistributes the official Apache APISIX Helm chart and deploys the Apache APISIX container image.

- Project: Apache APISIX
- Helm chart: `apisix` 2.16.0
- Application: Apache APISIX 3.17.0
- Source: https://github.com/apache/apisix-helm-chart
- License: Apache License 2.0; see [`APISIX-LICENSE.txt`](./APISIX-LICENSE.txt)
- Notice: see [`APISIX-NOTICE.txt`](./APISIX-NOTICE.txt)

OpsDiag does not modify the Apache APISIX source distribution. OpsDiag supplies product-specific standalone routing through a generated `apisix.yaml` mounted into the official chart workload.

The `opsdiag-app` chart also redistributes the official Bitnami PostgreSQL Helm chart twice, under independent `postgresql` and `tables-postgresql` aliases, and deploys the Bitnami PostgreSQL container image.

- Project: PostgreSQL packaged by Bitnami
- Helm chart: `postgresql` 18.7.11
- Application: PostgreSQL 18.4.0
- Source: https://github.com/bitnami/charts/tree/main/bitnami/postgresql
- License: Apache License 2.0 for the Helm chart; the vendored chart archive carries its upstream license

OpsDiag does not modify the Bitnami PostgreSQL source distribution. OpsDiag supplies separate main-App and Pipeline-Tables values through the two dependency aliases.
