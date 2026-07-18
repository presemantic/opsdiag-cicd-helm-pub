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

{{- define "opsdiag-app.resources" -}}
{{- $values := index .root.Values .component -}}
{{- if $values.resources -}}
{{ include "common.tplvalues.render" (dict "value" $values.resources "context" .root) }}
{{- else if $values.resourcesPreset -}}
{{ include "common.resources.preset" (dict "type" $values.resourcesPreset) }}
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

{{- define "opsdiag-app.schedulerWorkerTokenSecretName" -}}
{{- if .Values.api.schedulerWorkerToken.existingSecret -}}
{{- .Values.api.schedulerWorkerToken.existingSecret -}}
{{- else -}}
{{- printf "%s-scheduler-worker-token" (include "opsdiag-app.componentName" (dict "root" . "component" "api")) | trunc 63 | trimSuffix "-" -}}
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
