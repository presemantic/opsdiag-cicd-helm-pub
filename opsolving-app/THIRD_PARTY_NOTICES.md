# Third-party notices for opsolving-app

The `opsolving-app` chart redistributes the official Apache APISIX Helm chart and deploys the Apache APISIX container image.

- Project: Apache APISIX
- Helm chart: `apisix` 2.16.0
- Application: Apache APISIX 3.17.0
- Source: https://github.com/apache/apisix-helm-chart
- License: Apache License 2.0; see [`APISIX-LICENSE.txt`](./APISIX-LICENSE.txt)
- Notice: see [`APISIX-NOTICE.txt`](./APISIX-NOTICE.txt)

Opsolving does not modify the Apache APISIX source distribution. Opsolving supplies product-specific standalone routing through a generated `apisix.yaml` mounted into the official chart workload.

The `opsolving-app` chart deploys two independent PostgreSQL 18 instances from the Docker Official Image for PostgreSQL. PostgreSQL Kubernetes resources are implemented directly by Opsolving chart templates; no third-party PostgreSQL Helm chart is redistributed.

- Project: PostgreSQL
- Application: PostgreSQL 18.x
- Project source: https://www.postgresql.org
- Container image: `registry-1.docker.io/library/postgres:18`
- Image source and packaging: https://github.com/docker-library/postgres
- Image status: Docker Official Image
- PostgreSQL license: PostgreSQL License; see [`POSTGRESQL-LICENSE.txt`](./POSTGRESQL-LICENSE.txt)

The official image may also contain operating-system and supporting packages under their respective licenses. Their package copyright files are included in the image filesystem by the upstream Docker Official Image build.
