{{/*
Copyright Opsolving. All Rights Reserved.
SPDX-License-Identifier: APACHE-2.0
*/}}

{{- define "opsolving-app-connector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "opsolving-app-connector.configSecretName" -}}
{{- printf "%s-config" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
