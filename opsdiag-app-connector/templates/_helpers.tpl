{{/*
Copyright OpsDiag. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- define "opsdiag-app-connector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsdiag-app-connector.configSecretName" -}}
{{- printf "%s-config" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opsdiag-app-connector.selectorLabels" -}}
{{ include "common.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" .) }}
app.kubernetes.io/component: connector
{{- end -}}

{{- define "opsdiag-app-connector.podLabels" -}}
{{ include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" .) }}
app.kubernetes.io/component: connector
{{- with .Values.podLabels }}
{{ include "common.tplvalues.render" (dict "value" . "context" $) }}
{{- end }}
{{- end -}}
