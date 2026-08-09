{{/* Copyright OpsDiag. All Rights Reserved. SPDX-License-Identifier: APACHE-2.0 */}}

{{- define "opsdiag-app.componentName" -}}
{{- printf "%s-%s" (include "common.names.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app.selectorLabels" -}}
{{- $name := include "opsdiag-app.componentName" . -}}
app.kubernetes.io/name: {{ $name | quote }}
app.kubernetes.io/instance: {{ $name | quote }}
app.kubernetes.io/component: {{ .component | quote }}
{{- with (index .root.Values .component).podLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $.root) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app.podLabels" -}}
{{ include "opsdiag-app.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
{{- with .root.Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $.root) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app.serviceAccountName" -}}
{{- $values := index .root.Values .component -}}
{{- if $values.serviceAccount.create -}}
{{- default (include "opsdiag-app.componentName" .) $values.serviceAccount.name -}}
{{- else -}}
{{- default "default" $values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.configName" -}}
{{- printf "%s-config" (include "opsdiag-app.componentName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app.pgsql.fullname" -}}
{{- if .Values.pgsql.fullnameOverride -}}
{{- .Values.pgsql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if contains (default "pgsql" .Values.pgsql.nameOverride) .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (default "pgsql" .Values.pgsql.nameOverride) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.pgsql.secretName" -}}
{{- default (include "opsdiag-app.pgsql.fullname" .) .Values.pgsql.auth.existingSecret -}}
{{- end -}}

{{- define "opsdiag-app.pgsql.serviceAccountName" -}}
{{- if .Values.pgsql.primary.serviceAccount.create -}}
{{- default (include "opsdiag-app.pgsql.fullname" .) .Values.pgsql.primary.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.pgsql.primary.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.pgsql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opsdiag-app.pgsql.fullname" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "pgsql"
{{- end -}}

{{- define "opsdiag-app.pgsql.labels" -}}
{{ include "opsdiag-app.pgsql.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app.pgsql.url" -}}
{{- if trim .Values.api.config.database.url -}}
{{- tpl .Values.api.config.database.url . -}}
{{- else if not .Values.pgsql.enabled -}}
{{- fail "pgsql is disabled; api.config.database.url is required for an external PostgreSQL instance" -}}
{{- else if .Values.pgsql.auth.existingSecret -}}
{{- fail "pgsql uses auth.existingSecret; provide api.config.database.url because Helm cannot read that Secret" -}}
{{- else -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=disable" (required "pgsql.auth.username is required" .Values.pgsql.auth.username | urlquery) (required "pgsql.auth.password is required when api.config.database.url is empty" .Values.pgsql.auth.password | urlquery) (include "opsdiag-app.pgsql.fullname" .) .Values.pgsql.primary.service.ports.pgsql (required "pgsql.auth.database is required" .Values.pgsql.auth.database | urlquery) -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.fullname" -}}
{{- if (index .Values "pgsql-tables").fullnameOverride -}}
{{- (index .Values "pgsql-tables").fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if contains (default "pgsql-tables" (index .Values "pgsql-tables").nameOverride) .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (default "pgsql-tables" (index .Values "pgsql-tables").nameOverride) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.secretName" -}}
{{- default (include "opsdiag-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").auth.existingSecret -}}
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.serviceAccountName" -}}
{{- if (index .Values "pgsql-tables").primary.serviceAccount.create -}}
{{- default (include "opsdiag-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").primary.serviceAccount.name -}}
{{- else -}}
{{- default "default" (index .Values "pgsql-tables").primary.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opsdiag-app.pgsqlTables.fullname" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "pgsql-tables"
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.labels" -}}
{{ include "opsdiag-app.pgsqlTables.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app.pgsqlTables.url" -}}
{{- if trim .Values.api.config.tablesDatabase.url -}}
{{- tpl .Values.api.config.tablesDatabase.url . -}}
{{- else if not (index .Values "pgsql-tables").enabled -}}
{{- fail "pgsql-tables is disabled; api.config.tablesDatabase.url is required for an external PostgreSQL instance" -}}
{{- else if (index .Values "pgsql-tables").auth.existingSecret -}}
{{- fail "pgsql-tables uses auth.existingSecret; provide api.config.tablesDatabase.url because Helm cannot read that Secret" -}}
{{- else -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=disable" (required "pgsql-tables.auth.username is required" (index .Values "pgsql-tables").auth.username | urlquery) (required "pgsql-tables.auth.password is required when api.config.tablesDatabase.url is empty" (index .Values "pgsql-tables").auth.password | urlquery) (include "opsdiag-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").primary.service.ports.pgsql (required "pgsql-tables.auth.database is required" (index .Values "pgsql-tables").auth.database | urlquery) -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.componentServiceName" -}}
{{- $component := .component | required "exposure backend component is required" -}}
{{- if not (hasKey .root.Values $component) -}}
{{- fail (printf "unknown exposure backend component %q" $component) -}}
{{- end -}}
{{- include "opsdiag-app.componentName" (dict "root" .root "component" $component) -}}
{{- end -}}

{{- define "opsdiag-app.componentServiceURL" -}}
{{- $component := .component | required "service URL component is required" -}}
{{- if not (hasKey .root.Values $component) -}}
{{- fail (printf "unknown service URL component %q" $component) -}}
{{- end -}}
{{- $values := index .root.Values $component -}}
{{- printf "http://%s:%v" (include "opsdiag-app.componentName" (dict "root" .root "component" $component)) $values.service.ports.http -}}
{{- end -}}

{{- define "opsdiag-app.apisixFullname" -}}
{{- $values := .Values.apisix -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "apisix" $values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.apisixServiceName" -}}
{{- printf "%s-gateway" (include "opsdiag-app.apisixFullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app.apisixServicePort" -}}
{{- .Values.apisix.service.http.servicePort -}}
{{- end -}}

{{- define "opsdiag-app.openshiftRouteTLS" -}}
termination: {{ .Values.openshiftRoute.tls.termination | quote }}
insecureEdgeTerminationPolicy: {{ .Values.openshiftRoute.tls.insecureEdgeTerminationPolicy | quote }}
{{- with .Values.openshiftRoute.tls.certificate }}
certificate: {{ . | quote }}
{{- end }}
{{- with .Values.openshiftRoute.tls.key }}
key: {{ . | quote }}
{{- end }}
{{- with .Values.openshiftRoute.tls.caCertificate }}
caCertificate: {{ . | quote }}
{{- end }}
{{- with .Values.openshiftRoute.tls.destinationCACertificate }}
destinationCACertificate: {{ . | quote }}
{{- end }}
{{- end -}}
