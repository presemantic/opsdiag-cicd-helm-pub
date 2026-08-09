{{/* Copyright OpsDiag. All Rights Reserved. SPDX-License-Identifier: APACHE-2.0 */}}

{{- define "opsdiag-app.postgresql.resources" -}}
{{- $root := .root -}}
{{- $values := .values -}}
{{- $context := dict "root" $root "values" $values "alias" .alias -}}
{{- $fullname := include "opsdiag-app.postgresqlFullname" $context -}}
{{- $statefulsetName := include "opsdiag-app.postgresqlStatefulsetName" $context -}}
{{- $secretName := include "opsdiag-app.postgresqlSecretName" $context -}}
{{- $passwordKey := required (printf "%s.auth.secretKeys.userPasswordKey is required" .valuePath) $values.auth.secretKeys.userPasswordKey -}}
{{- if $values.enabled }}
{{- if not $values.auth.existingSecret }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretName | quote }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.postgresqlLabels" $context | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: "-20"
    {{- with $root.Values.commonAnnotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
type: Opaque
stringData:
  {{ $passwordKey }}: {{ required (printf "%s.auth.password is required when auth.existingSecret is empty" .valuePath) $values.auth.password | quote }}
{{- end }}
{{- if $values.primary.serviceAccount.create }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "opsdiag-app.postgresqlServiceAccountName" $context | quote }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.postgresqlLabels" $context | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: "-20"
    {{- with $root.Values.commonAnnotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
    {{- with $values.primary.serviceAccount.annotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
automountServiceAccountToken: {{ $values.primary.serviceAccount.automountServiceAccountToken }}
{{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $fullname | quote }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.postgresqlLabels" $context | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: "-20"
    {{- with $root.Values.commonAnnotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
    {{- with $values.primary.service.annotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
spec:
  type: {{ $values.primary.service.type }}
  {{- with $values.primary.service.clusterIP }}
  clusterIP: {{ . | quote }}
  {{- end }}
  sessionAffinity: {{ $values.primary.service.sessionAffinity }}
  ports:
    - name: postgresql
      port: {{ $values.primary.service.ports.postgresql }}
      protocol: TCP
      targetPort: postgresql
  selector:
    {{- include "opsdiag-app.postgresqlSelectorLabels" $context | nindent 4 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ printf "%s-hl" $fullname | trunc 63 | trimSuffix "-" | quote }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.postgresqlLabels" $context | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: "-20"
    {{- with $root.Values.commonAnnotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - name: postgresql
      port: {{ $values.primary.service.ports.postgresql }}
      protocol: TCP
      targetPort: postgresql
  selector:
    {{- include "opsdiag-app.postgresqlSelectorLabels" $context | nindent 4 }}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $statefulsetName | quote }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.postgresqlLabels" $context | nindent 4 }}
  annotations:
    argocd.argoproj.io/sync-wave: "-20"
    {{- with $root.Values.commonAnnotations }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
    {{- end }}
spec:
  serviceName: {{ printf "%s-hl" $fullname | trunc 63 | trimSuffix "-" | quote }}
  replicas: 1
  podManagementPolicy: {{ $values.primary.podManagementPolicy }}
  updateStrategy:
    {{- include "common.tplvalues.render" (dict "value" $values.primary.updateStrategy "context" $root) | nindent 4 }}
  selector:
    matchLabels:
      {{- include "opsdiag-app.postgresqlSelectorLabels" $context | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "opsdiag-app.postgresqlLabels" $context | nindent 8 }}
        {{- with $values.primary.podLabels }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
        {{- end }}
      annotations:
        checksum/auth: {{ printf "%s:%s:%s" $secretName $passwordKey $values.auth.password | sha256sum }}
        {{- with $values.primary.podAnnotations }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "opsdiag-app.postgresqlServiceAccountName" $context | quote }}
      automountServiceAccountToken: {{ $values.primary.serviceAccount.automountServiceAccountToken }}
      enableServiceLinks: false
      {{- include "common.images.renderPullSecrets" (dict "images" (list $values.image) "context" $root) | nindent 6 }}
      {{- if $values.primary.podSecurityContext.enabled }}
      securityContext:
        {{- omit $values.primary.podSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- with $values.primary.priorityClassName }}
      priorityClassName: {{ . | quote }}
      {{- end }}
      {{- with $values.primary.schedulerName }}
      schedulerName: {{ . | quote }}
      {{- end }}
      terminationGracePeriodSeconds: {{ $values.primary.terminationGracePeriodSeconds }}
      containers:
        - name: postgresql
          image: {{ include "common.images.image" (dict "imageRoot" $values.image "global" $root.Values.global "chart" $root.Chart) | quote }}
          imagePullPolicy: {{ $values.image.pullPolicy }}
          {{- if $values.primary.containerSecurityContext.enabled }}
          securityContext:
            {{- omit $values.primary.containerSecurityContext "enabled" | toYaml | nindent 12 }}
          {{- end }}
          env:
            - name: POSTGRES_USER
              value: {{ required (printf "%s.auth.username is required" .valuePath) $values.auth.username | quote }}
            - name: POSTGRES_DB
              value: {{ required (printf "%s.auth.database is required" .valuePath) $values.auth.database | quote }}
            - name: POSTGRES_PASSWORD_FILE
              value: /run/secrets/postgresql/password
            - name: PGDATA
              value: /var/lib/postgresql/18/docker
          ports:
            - name: postgresql
              containerPort: {{ $values.primary.service.ports.postgresql }}
              protocol: TCP
          {{- if $values.primary.startupProbe.enabled }}
          startupProbe:
            exec:
              command:
                - /bin/sh
                - -ec
                - exec pg_isready -h 127.0.0.1 -p {{ $values.primary.service.ports.postgresql }} -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            {{- include "common.tplvalues.render" (dict "value" $values.primary.startupProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- if $values.primary.readinessProbe.enabled }}
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - -ec
                - exec pg_isready -h 127.0.0.1 -p {{ $values.primary.service.ports.postgresql }} -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            {{- include "common.tplvalues.render" (dict "value" $values.primary.readinessProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- if $values.primary.livenessProbe.enabled }}
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -ec
                - exec pg_isready -h 127.0.0.1 -p {{ $values.primary.service.ports.postgresql }} -U "$POSTGRES_USER" -d "$POSTGRES_DB"
            {{- include "common.tplvalues.render" (dict "value" $values.primary.livenessProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- with $values.primary.resources }}
          resources:
            {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql
            - name: password
              mountPath: /run/secrets/postgresql
              readOnly: true
            - name: tmp
              mountPath: /tmp
            - name: run
              mountPath: /var/run/postgresql
            - name: shm
              mountPath: /dev/shm
      volumes:
        - name: password
          secret:
            secretName: {{ $secretName | quote }}
            defaultMode: 0440
            items:
              - key: {{ $passwordKey | quote }}
                path: password
        - name: tmp
          emptyDir: {}
        - name: run
          emptyDir: {}
        - name: shm
          emptyDir:
            medium: Memory
        {{- if $values.primary.persistence.existingClaim }}
        - name: data
          persistentVolumeClaim:
            claimName: {{ tpl $values.primary.persistence.existingClaim $root | quote }}
        {{- else if not $values.primary.persistence.enabled }}
        - name: data
          emptyDir: {}
        {{- end }}
      {{- with $values.primary.affinity }}
      affinity:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- with $values.primary.nodeSelector }}
      nodeSelector:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- with $values.primary.tolerations }}
      tolerations:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- with $values.primary.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
  {{- if and $values.primary.persistence.enabled (not $values.primary.persistence.existingClaim) }}
  volumeClaimTemplates:
    - metadata:
        name: data
        {{- with $values.primary.persistence.annotations }}
        annotations:
          {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 10 }}
        {{- end }}
      spec:
        accessModes:
          {{- toYaml $values.primary.persistence.accessModes | nindent 10 }}
        {{- if eq "-" $values.primary.persistence.storageClass }}
        storageClassName: ""
        {{- else if $values.primary.persistence.storageClass }}
        storageClassName: {{ tpl $values.primary.persistence.storageClass $root | quote }}
        {{- end }}
        {{- with $values.primary.persistence.selector }}
        selector:
          {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 10 }}
        {{- end }}
        resources:
          requests:
            storage: {{ $values.primary.persistence.size | quote }}
  {{- end }}
{{- end }}
{{- end -}}
