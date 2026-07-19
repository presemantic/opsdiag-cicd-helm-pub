{{- define "opsdiag-app.deployment" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $values := index $root.Values $component -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "opsdiag-app.componentName" . }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.podLabels" . | nindent 4 }}
  {{- with $root.Values.commonAnnotations }}
  annotations:
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
  {{- end }}
spec:
  replicas: {{ $values.replicaCount }}
  revisionHistoryLimit: {{ $values.revisionHistoryLimit }}
  strategy:
    {{- include "common.tplvalues.render" (dict "value" $values.updateStrategy "context" $root) | nindent 4 }}
  selector:
    matchLabels:
      {{- include "opsdiag-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "opsdiag-app.podLabels" . | nindent 8 }}
      annotations:
        {{- if eq $component "api" }}
        checksum/config: {{ include (print $root.Template.BasePath "/api/secret.yaml") $root | sha256sum }}
        {{- else if eq $component "agent" }}
        checksum/config: {{ include (print $root.Template.BasePath "/agent/secret.yaml") $root | sha256sum }}
        {{- else if eq $component "sched" }}
        checksum/config: {{ include (print $root.Template.BasePath "/sched/secret.yaml") $root | sha256sum }}
        {{- end }}
        {{- with $values.podAnnotations }}
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "opsdiag-app.serviceAccountName" . }}
      automountServiceAccountToken: {{ $values.serviceAccount.automountServiceAccountToken }}
      {{- include "common.images.renderPullSecrets" (dict "images" (list $values.image) "context" $root) | nindent 6 }}
      {{- if $values.podSecurityContext.enabled }}
      securityContext:
        {{- omit $values.podSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- with $values.priorityClassName }}
      priorityClassName: {{ . | quote }}
      {{- end }}
      {{- with $values.schedulerName }}
      schedulerName: {{ . | quote }}
      {{- end }}
      terminationGracePeriodSeconds: {{ $values.terminationGracePeriodSeconds }}
      {{- with $values.nodeSelector }}
      nodeSelector:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- $affinity := include "opsdiag-app.affinity" . | trim }}
      {{- if $affinity }}
      affinity:
        {{- $affinity | nindent 8 }}
      {{- end }}
      {{- with $values.tolerations }}
      tolerations:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      {{- with $values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ $component | quote }}
          image: {{ include "common.images.image" (dict "imageRoot" $values.image "global" $root.Values.global "chart" $root.Chart) | quote }}
          imagePullPolicy: {{ $values.image.pullPolicy }}
          {{- if $values.containerSecurityContext.enabled }}
          securityContext:
            {{- omit $values.containerSecurityContext "enabled" | toYaml | nindent 12 }}
          {{- end }}
          ports:
            - name: http
              containerPort: {{ $values.containerPorts.http }}
              protocol: TCP
          {{- if $values.extraEnvVars }}
          env:
            {{- include "common.tplvalues.render" (dict "value" $values.extraEnvVars "context" $root) | nindent 12 }}
          {{- end }}
          {{- if or $values.extraEnvVarsCM $values.extraEnvVarsSecret }}
          envFrom:
            {{- with $values.extraEnvVarsCM }}
            - configMapRef:
                name: {{ . }}
            {{- end }}
            {{- with $values.extraEnvVarsSecret }}
            - secretRef:
                name: {{ . }}
            {{- end }}
          {{- end }}
          {{- $resources := include "opsdiag-app.resources" . | trim }}
          {{- if $resources }}
          resources:
            {{- $resources | nindent 12 }}
          {{- end }}
          {{- if $values.livenessProbe.enabled }}
          livenessProbe:
            {{- include "common.tplvalues.render" (dict "value" $values.livenessProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- if $values.readinessProbe.enabled }}
          readinessProbe:
            {{- include "common.tplvalues.render" (dict "value" $values.readinessProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- if $values.startupProbe.enabled }}
          startupProbe:
            {{- include "common.tplvalues.render" (dict "value" $values.startupProbe.spec "context" $root) | nindent 12 }}
          {{- end }}
          {{- if ne $component "front" }}
          volumeMounts:
            - name: app-config
              mountPath: /app/config.yaml
              subPath: config.yaml
              readOnly: true
          {{- else }}
          volumeMounts:
            - name: nginx-cache
              mountPath: /var/cache/nginx
            - name: nginx-run
              mountPath: /var/run
            - name: nginx-tmp
              mountPath: /tmp
          {{- end }}
      {{- if ne $component "front" }}
      volumes:
        - name: app-config
          secret:
            secretName: {{ include "opsdiag-app.configName" . }}
      {{- else }}
      volumes:
        - name: nginx-cache
          emptyDir: {}
        - name: nginx-run
          emptyDir: {}
        - name: nginx-tmp
          emptyDir: {}
      {{- end }}
{{- end -}}

{{- define "opsdiag-app.service" -}}
{{- $root := .root -}}
{{- $values := index $root.Values .component -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "opsdiag-app.componentName" . }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.podLabels" . | nindent 4 }}
  {{- with $values.service.annotations }}
  annotations:
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
  {{- end }}
spec:
  type: {{ $values.service.type }}
  {{- with $values.service.clusterIP }}
  clusterIP: {{ . }}
  {{- end }}
  ports:
    - name: http
      port: {{ $values.service.ports.http }}
      targetPort: http
      protocol: TCP
  selector:
    {{- include "opsdiag-app.selectorLabels" . | nindent 4 }}
{{- end -}}

{{- define "opsdiag-app.serviceAccount" -}}
{{- $root := .root -}}
{{- $values := index $root.Values .component -}}
{{- if $values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "opsdiag-app.serviceAccountName" . }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.podLabels" . | nindent 4 }}
  {{- with $values.serviceAccount.annotations }}
  annotations:
    {{- include "common.tplvalues.render" (dict "value" . "context" $root) | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ $values.serviceAccount.automountServiceAccountToken }}
{{- end }}
{{- end -}}

{{- define "opsdiag-app.podDisruptionBudget" -}}
{{- $root := .root -}}
{{- $values := index $root.Values .component -}}
{{- if $values.podDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "opsdiag-app.componentName" . }}
  namespace: {{ include "common.names.namespace" $root | quote }}
  labels:
    {{- include "opsdiag-app.podLabels" . | nindent 4 }}
spec:
  {{- if ne (toString $values.podDisruptionBudget.minAvailable) "" }}
  minAvailable: {{ $values.podDisruptionBudget.minAvailable }}
  {{- end }}
  {{- if ne (toString $values.podDisruptionBudget.maxUnavailable) "" }}
  maxUnavailable: {{ $values.podDisruptionBudget.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "opsdiag-app.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end -}}
