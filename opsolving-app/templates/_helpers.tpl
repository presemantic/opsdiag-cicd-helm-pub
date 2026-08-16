{{/* Copyright Opsolving. All Rights Reserved. SPDX-License-Identifier: APACHE-2.0 */}}

{{- define "opsolving-app.componentName" -}}
{{- printf "%s-%s" (include "common.names.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.selectorLabels" -}}
{{- $name := include "opsolving-app.componentName" . -}}
app.kubernetes.io/name: {{ $name | quote }}
app.kubernetes.io/instance: {{ $name | quote }}
app.kubernetes.io/component: {{ .component | quote }}
{{- with (index .root.Values .component).podLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $.root) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.podLabels" -}}
{{ include "opsolving-app.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
{{- with .root.Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $.root) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.serviceAccountName" -}}
{{- $values := index .root.Values .component -}}
{{- if $values.serviceAccount.create -}}
{{- default (include "opsolving-app.componentName" .) $values.serviceAccount.name -}}
{{- else -}}
{{- default "default" $values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app.configName" -}}
{{- printf "%s-config" (include "opsolving-app.componentName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.pgsql.fullname" -}}
{{- printf "%s-pgsql" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.pgsql.secretName" -}}
{{- default (include "opsolving-app.pgsql.fullname" .) .Values.pgsql.auth.existingSecret -}}
{{- end -}}

{{- define "opsolving-app.pgsql.serviceAccountName" -}}
{{- if .Values.pgsql.primary.serviceAccount.create -}}
{{- default (include "opsolving-app.pgsql.fullname" .) .Values.pgsql.primary.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.pgsql.primary.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app.pgsql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opsolving-app.pgsql.fullname" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "pgsql"
{{- end -}}

{{- define "opsolving-app.pgsql.labels" -}}
{{ include "opsolving-app.pgsql.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.pgsql.podLabels" -}}
{{ include "opsolving-app.pgsql.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.pgsql.url" -}}
{{- if trim .Values.api.config.database.url -}}
{{- tpl .Values.api.config.database.url . -}}
{{- else if not .Values.pgsql.enabled -}}
{{- fail "pgsql is disabled; api.config.database.url is required for an external PostgreSQL instance" -}}
{{- else if .Values.pgsql.auth.existingSecret -}}
{{- fail "pgsql uses auth.existingSecret; provide api.config.database.url because Helm cannot read that Secret" -}}
{{- else -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=disable" (required "pgsql.auth.username is required" .Values.pgsql.auth.username | urlquery) (required "pgsql.auth.password is required when api.config.database.url is empty" .Values.pgsql.auth.password | urlquery) (include "opsolving-app.pgsql.fullname" .) .Values.pgsql.primary.service.ports.pgsql (required "pgsql.auth.database is required" .Values.pgsql.auth.database | urlquery) -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.fullname" -}}
{{- printf "%s-pgsql-tables" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.secretName" -}}
{{- default (include "opsolving-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").auth.existingSecret -}}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.serviceAccountName" -}}
{{- if (index .Values "pgsql-tables").primary.serviceAccount.create -}}
{{- default (include "opsolving-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").primary.serviceAccount.name -}}
{{- else -}}
{{- default "default" (index .Values "pgsql-tables").primary.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opsolving-app.pgsqlTables.fullname" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "pgsql-tables"
{{- end -}}

{{- define "opsolving-app.pgsqlTables.labels" -}}
{{ include "opsolving-app.pgsqlTables.selectorLabels" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.podLabels" -}}
{{ include "opsolving-app.pgsqlTables.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ include "common.names.fullname" . | quote }}
{{- with .Values.commonLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsolving-app.pgsqlTables.url" -}}
{{- if trim .Values.api.config.tablesDatabase.url -}}
{{- tpl .Values.api.config.tablesDatabase.url . -}}
{{- else if not (index .Values "pgsql-tables").enabled -}}
{{- fail "pgsql-tables is disabled; api.config.tablesDatabase.url is required for an external PostgreSQL instance" -}}
{{- else if (index .Values "pgsql-tables").auth.existingSecret -}}
{{- fail "pgsql-tables uses auth.existingSecret; provide api.config.tablesDatabase.url because Helm cannot read that Secret" -}}
{{- else -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=disable" (required "pgsql-tables.auth.username is required" (index .Values "pgsql-tables").auth.username | urlquery) (required "pgsql-tables.auth.password is required when api.config.tablesDatabase.url is empty" (index .Values "pgsql-tables").auth.password | urlquery) (include "opsolving-app.pgsqlTables.fullname" .) (index .Values "pgsql-tables").primary.service.ports.pgsql (required "pgsql-tables.auth.database is required" (index .Values "pgsql-tables").auth.database | urlquery) -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app.componentServiceName" -}}
{{- $component := .component | required "exposure backend component is required" -}}
{{- if not (hasKey .root.Values $component) -}}
{{- fail (printf "unknown exposure backend component %q" $component) -}}
{{- end -}}
{{- include "opsolving-app.componentName" (dict "root" .root "component" $component) -}}
{{- end -}}

{{- define "opsolving-app.componentServiceURL" -}}
{{- $component := .component | required "service URL component is required" -}}
{{- if not (hasKey .root.Values $component) -}}
{{- fail (printf "unknown service URL component %q" $component) -}}
{{- end -}}
{{- $values := index .root.Values $component -}}
{{- printf "http://%s:%v" (include "opsolving-app.componentName" (dict "root" .root "component" $component)) $values.service.ports.http -}}
{{- end -}}

{{- define "opsolving-app.apisixFullname" -}}
{{- printf "%s-apisix" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.apisixServiceName" -}}
{{- printf "%s-gateway" (include "opsolving-app.apisixFullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsolving-app.apisixServicePort" -}}
{{- .Values.apisix.service.http.servicePort -}}
{{- end -}}

{{/* Return the explicit external origin or derive it from the active chart-owned exposure. */}}
{{- define "opsolving-app.externalURL" -}}
{{- if trim .Values.global.externalURL -}}
{{- tpl .Values.global.externalURL . | trimSuffix "/" -}}
{{- else if .Values.openshiftRoute.enabled -}}
{{- printf "%s://%s" (ternary "https" "http" .Values.openshiftRoute.tls.enabled) (tpl (required "openshiftRoute.hostname is required when openshiftRoute.enabled is true" .Values.openshiftRoute.hostname) .) -}}
{{- else if .Values.ingress.enabled -}}
{{- printf "%s://%s" (ternary "https" "http" .Values.ingress.tls) (tpl (required "ingress.hostname is required when ingress.enabled is true" .Values.ingress.hostname) .) -}}
{{- else if .Values.istio.enabled -}}
{{- printf "%s://%s" (ternary "https" "http" .Values.istio.gateway.tls.enabled) (tpl (required "istio.hostname is required when istio.enabled is true" .Values.istio.hostname) .) -}}
{{- else -}}
https://app.local
{{- end -}}
{{- end -}}

{{- define "opsolving-app.openshiftRouteTLS" -}}
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
