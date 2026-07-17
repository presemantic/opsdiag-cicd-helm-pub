{{/*
Copyright OpsDiag. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- define "opsdiag-app-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app-api.configMapName" -}}
{{- printf "%s-config" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app-api.schedulerWorkerTokenSecretName" -}}
{{- if .Values.schedulerWorkerToken.existingSecret -}}
{{- .Values.schedulerWorkerToken.existingSecret -}}
{{- else -}}
{{- printf "%s-scheduler-worker-token" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app-api.selectorLabels" -}}
{{ include "common.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" .) }}
app.kubernetes.io/component: {{ .Values.component | quote }}
{{- end -}}

{{- define "opsdiag-app-api.podLabels" -}}
{{ include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" .) }}
app.kubernetes.io/component: {{ .Values.component | quote }}
{{- with .Values.podLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app-api.resources" -}}
{{- if .Values.resources -}}
{{ include "common.tplvalues.render" (dict "value" .Values.resources "context" .) }}
{{- else if .Values.resourcesPreset -}}
{{ include "common.resources.preset" (dict "type" .Values.resourcesPreset) }}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app-api.affinity" -}}
{{- if .Values.affinity -}}
{{ include "common.tplvalues.render" (dict "value" .Values.affinity "context" .) }}
{{- else -}}
{{- if .Values.podAffinityPreset }}
podAffinity:
{{ include "common.affinities.pods" (dict "type" .Values.podAffinityPreset "component" .Values.component "customLabels" .Values.podLabels "context" .) | nindent 2 }}
{{- end }}
{{- if .Values.podAntiAffinityPreset }}
podAntiAffinity:
{{ include "common.affinities.pods" (dict "type" .Values.podAntiAffinityPreset "component" .Values.component "customLabels" .Values.podLabels "context" .) | nindent 2 }}
{{- end }}
{{- if .Values.nodeAffinityPreset.type }}
nodeAffinity:
{{ include "common.affinities.nodes" (dict "type" .Values.nodeAffinityPreset.type "key" .Values.nodeAffinityPreset.key "values" .Values.nodeAffinityPreset.values) | nindent 2 }}
{{- end }}
{{- end -}}
{{- end -}}
