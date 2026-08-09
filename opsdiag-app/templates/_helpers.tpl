{{/* Copyright OpsDiag. All Rights Reserved. SPDX-License-Identifier: APACHE-2.0 */}}

{{- define "opsdiag-app.componentName" -}}
{{- printf "%s-%s" (include "common.names.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app.componentValues" -}}
{{- index .root.Values .component | toYaml -}}
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

{{- define "opsdiag-app.postgresqlFullname" -}}
{{- $values := .values -}}
{{- if $values.fullnameOverride -}}
{{- $values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .alias $values.nameOverride -}}
{{- if contains $name .root.Release.Name -}}
{{- .root.Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .root.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.postgresqlURL" -}}
{{- $root := .root -}}
{{- $values := .values -}}
{{- $explicitURL := trim .explicitURL -}}
{{- if $explicitURL -}}
{{- tpl $explicitURL $root -}}
{{- else if $values.enabled -}}
{{- if $values.auth.existingSecret -}}
{{- fail (printf "%s uses auth.existingSecret; provide the complete %s URL because the parent chart cannot read that Secret during rendering" .valuePath .urlPath) -}}
{{- end -}}
{{- $username := required (printf "%s.auth.username is required" .valuePath) $values.auth.username -}}
{{- $password := required (printf "%s.auth.password is required when %s is empty" .valuePath .urlPath) $values.auth.password -}}
{{- $database := required (printf "%s.auth.database is required" .valuePath) $values.auth.database -}}
{{- $host := include "opsdiag-app.postgresqlFullname" (dict "root" $root "values" $values "alias" .alias) -}}
{{- $port := $values.primary.service.ports.postgresql -}}
{{- $sslMode := ternary "require" "disable" $values.tls.enabled -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=%s" ($username | urlquery) ($password | urlquery) $host $port ($database | urlquery) $sslMode -}}
{{- else -}}
{{- fail (printf "%s is disabled; %s is required for an external PostgreSQL instance" .valuePath .urlPath) -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.databaseURL" -}}
{{- include "opsdiag-app.postgresqlURL" (dict
  "root" .
  "values" .Values.postgresql
  "alias" "postgresql"
  "valuePath" "postgresql"
  "urlPath" "api.config.database.url"
  "explicitURL" .Values.api.config.database.url
) -}}
{{- end -}}

{{- define "opsdiag-app.tablesDatabaseURL" -}}
{{- $values := index .Values "tables-postgresql" -}}
{{- include "opsdiag-app.postgresqlURL" (dict
  "root" .
  "values" $values
  "alias" "tables-postgresql"
  "valuePath" "tables-postgresql"
  "urlPath" "api.config.tablesDatabase.url"
  "explicitURL" .Values.api.config.tablesDatabase.url
) -}}
{{- end -}}

{{- define "opsdiag-app.resources" -}}
{{- $values := index .root.Values .component -}}
{{- if $values.resources -}}
{{ include "common.tplvalues.render" (dict "value" $values.resources "context" .root) }}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app.affinity" -}}
{{- $values := index .root.Values .component -}}
{{- if $values.affinity -}}
{{ include "common.tplvalues.render" (dict "value" $values.affinity "context" .root) }}
{{- else -}}
{{- if $values.podAffinityPreset }}
podAffinity:
{{ include "common.affinities.pods" (dict "type" $values.podAffinityPreset "component" .component "customLabels" $values.podLabels "context" .root) | nindent 2 }}
{{- end }}
{{- if $values.podAntiAffinityPreset }}
podAntiAffinity:
{{ include "common.affinities.pods" (dict "type" $values.podAntiAffinityPreset "component" .component "customLabels" $values.podLabels "context" .root) | nindent 2 }}
{{- end }}
{{- if $values.nodeAffinityPreset.type }}
nodeAffinity:
{{ include "common.affinities.nodes" (dict "type" $values.nodeAffinityPreset.type "key" $values.nodeAffinityPreset.key "values" $values.nodeAffinityPreset.values) | nindent 2 }}
{{- end }}
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
