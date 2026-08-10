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
