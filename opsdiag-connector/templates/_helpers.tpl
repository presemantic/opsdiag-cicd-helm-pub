{{/*
Copyright OpsDiag. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- define "opsdiag-connector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-connector.configMapName" -}}
{{- printf "%s-config" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-connector.secretName" -}}
{{- if .Values.connector.existingSecret -}}
{{- .Values.connector.existingSecret -}}
{{- else -}}
{{- printf "%s-license" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-connector.selectorLabels" -}}
{{ include "common.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" .) }}
app.kubernetes.io/component: connector
{{- end -}}

{{- define "opsdiag-connector.podLabels" -}}
{{ include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" .) }}
app.kubernetes.io/component: connector
{{- with .Values.podLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-connector.resources" -}}
{{- if .Values.resources -}}
{{ include "common.tplvalues.render" (dict "value" .Values.resources "context" .) }}
{{- else if .Values.resourcesPreset -}}
{{ include "common.resources.preset" (dict "type" .Values.resourcesPreset) }}
{{- end -}}
{{- end -}}

{{- define "opsdiag-connector.affinity" -}}
{{- if .Values.affinity -}}
{{ include "common.tplvalues.render" (dict "value" .Values.affinity "context" .) }}
{{- else -}}
{{- if .Values.podAffinityPreset }}
podAffinity:
{{ include "common.affinities.pods" (dict "type" .Values.podAffinityPreset "component" "connector" "customLabels" .Values.podLabels "context" .) | nindent 2 }}
{{- end }}
{{- if .Values.podAntiAffinityPreset }}
podAntiAffinity:
{{ include "common.affinities.pods" (dict "type" .Values.podAntiAffinityPreset "component" "connector" "customLabels" .Values.podLabels "context" .) | nindent 2 }}
{{- end }}
{{- if .Values.nodeAffinityPreset.type }}
nodeAffinity:
{{ include "common.affinities.nodes" (dict "type" .Values.nodeAffinityPreset.type "key" .Values.nodeAffinityPreset.key "values" .Values.nodeAffinityPreset.values) | nindent 2 }}
{{- end }}
{{- end -}}
{{- end -}}
