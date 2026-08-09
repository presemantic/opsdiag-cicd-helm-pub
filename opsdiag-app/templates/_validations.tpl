{{/* Copyright OpsDiag. All Rights Reserved. SPDX-License-Identifier: Apache-2.0 */}}

{{/* Validate the fixed standalone APISIX deployment and application routing contract. */}}
{{- define "opsdiag-app.validateApisix" -}}
{{- if .Values.apisix.useDaemonSet -}}
{{- fail "opsdiag-app requires APISIX to run as a Deployment; apisix.useDaemonSet must be false" -}}
{{- end -}}
{{- if .Values.apisix.autoscaling.enabled -}}
{{- fail "opsdiag-app owns a fixed highly available APISIX Deployment; apisix.autoscaling.enabled must be false" -}}
{{- end -}}
{{- if .Values.apisix.rbac.create -}}
{{- fail "standalone APISIX must not receive Kubernetes API permissions; apisix.rbac.create must be false" -}}
{{- end -}}
{{- if lt (int .Values.apisix.replicaCount) 2 -}}
{{- fail "opsdiag-app requires at least two APISIX replicas" -}}
{{- end -}}
{{- if ne .Values.apisix.service.type "ClusterIP" -}}
{{- fail "APISIX must remain internal; apisix.service.type must be ClusterIP" -}}
{{- end -}}
{{- if .Values.apisix.service.externalTrafficPolicy -}}
{{- fail "APISIX uses a ClusterIP Service; apisix.service.externalTrafficPolicy must be empty" -}}
{{- end -}}
{{- if not .Values.apisix.service.http.enabled -}}
{{- fail "APISIX HTTP gateway service must be enabled" -}}
{{- end -}}
{{- if gt (len .Values.apisix.service.externalIPs) 0 -}}
{{- fail "APISIX must remain internal; apisix.service.externalIPs must be empty" -}}
{{- end -}}
{{- if gt (len .Values.apisix.service.http.additionalContainerPorts) 0 -}}
{{- fail "opsdiag-app exposes one APISIX HTTP listener; additionalContainerPorts must be empty" -}}
{{- end -}}
{{- if .Values.apisix.service.stream.enabled -}}
{{- fail "opsdiag-app does not permit APISIX TCP or UDP stream listeners" -}}
{{- end -}}
{{- if .Values.apisix.apisix.ssl.enabled -}}
{{- fail "TLS terminates at the platform exposure; apisix.apisix.ssl.enabled must be false" -}}
{{- end -}}
{{- if ne .Values.apisix.apisix.deployment.mode "standalone" -}}
{{- fail "opsdiag-app requires apisix.apisix.deployment.mode=standalone" -}}
{{- end -}}
{{- if ne .Values.apisix.apisix.deployment.role "data_plane" -}}
{{- fail "opsdiag-app requires apisix.apisix.deployment.role=data_plane" -}}
{{- end -}}
{{- if ne .Values.apisix.apisix.deployment.role_data_plane.config_provider "yaml" -}}
{{- fail "opsdiag-app requires the APISIX standalone YAML configuration provider" -}}
{{- end -}}
{{- if .Values.apisix.etcd.enabled -}}
{{- fail "opsdiag-app standalone APISIX does not permit etcd" -}}
{{- end -}}
{{- if or (gt (len .Values.apisix.externalEtcd.host) 0) .Values.apisix.externalEtcd.user .Values.apisix.externalEtcd.password .Values.apisix.externalEtcd.existingSecret -}}
{{- fail "opsdiag-app standalone APISIX does not permit external etcd configuration" -}}
{{- end -}}
{{- if (index .Values.apisix "ingress-controller").enabled -}}
{{- fail "opsdiag-app does not permit the APISIX Ingress Controller or its CRDs" -}}
{{- end -}}
{{- if .Values.apisix.apisix.admin.enabled -}}
{{- fail "opsdiag-app standalone APISIX does not permit the Admin API" -}}
{{- end -}}
{{- if .Values.apisix.apisix.admin.enable_admin_ui -}}
{{- fail "opsdiag-app does not permit the APISIX Admin UI or dashboard" -}}
{{- end -}}
{{- if .Values.apisix.control.enabled -}}
{{- fail "opsdiag-app standalone APISIX does not permit the Control API" -}}
{{- end -}}
{{- if .Values.apisix.apisix.prometheus.enabled -}}
{{- fail "opsdiag-app exposes only the APISIX gateway Service; the APISIX metrics Service must remain disabled" -}}
{{- end -}}
{{- if .Values.apisix.ingress.enabled -}}
{{- fail "the APISIX subchart Ingress must remain disabled; use the opsdiag-app exposure values" -}}
{{- end -}}
{{- if .Values.apisix.metrics.serviceMonitor.enabled -}}
{{- fail "opsdiag-app does not permit the APISIX subchart ServiceMonitor" -}}
{{- end -}}
{{- if .Values.apisix.apisix.deployment.standalone.config -}}
{{- fail "standalone APISIX routing must come only from the parent apisix.yaml ConfigMap" -}}
{{- end -}}
{{- if not .Values.apisix.apisix.deployment.standalone.existingConfigMap -}}
{{- fail "apisix.apisix.deployment.standalone.existingConfigMap is required" -}}
{{- end -}}

{{- range $component := list "api" "front" "mcp-proxy" "vcs" -}}
{{- if ne (index $.Values $component).service.type "ClusterIP" -}}
{{- fail (printf "%s.service.type must be ClusterIP because APISIX is the only public application entrypoint" $component) -}}
{{- end -}}
{{- end -}}

{{- if eq (len .Values.gateway.routing.routes) 0 -}}
{{- fail "gateway.routing.routes must contain at least one APISIX route" -}}
{{- end -}}
{{- $seenRouteIDs := dict -}}
{{- range $route := .Values.gateway.routing.routes -}}
{{- $routeID := required "gateway.routing.routes[].id is required" $route.id -}}
{{- if hasKey $seenRouteIDs $routeID -}}
{{- fail (printf "duplicate APISIX route id %q" $routeID) -}}
{{- end -}}
{{- $_ := set $seenRouteIDs $routeID true -}}
{{- if eq (len $route.uris) 0 -}}
{{- fail (printf "gateway route %q requires at least one URI" $routeID) -}}
{{- end -}}
{{- range $uri := $route.uris -}}
{{- if not (hasPrefix "/" $uri) -}}
{{- fail (printf "gateway route %q URI %q must start with /" $routeID $uri) -}}
{{- end -}}
{{- end -}}
{{- if not $route.upstream -}}
{{- fail (printf "gateway route %q requires an upstream" $routeID) -}}
{{- end -}}
{{- if not (hasKey $.Values.gateway.routing.upstreams $route.upstream) -}}
{{- fail (printf "gateway route %q references unknown upstream %q" $routeID $route.upstream) -}}
{{- end -}}
{{- with index $.Values.gateway.routing.upstreams $route.upstream -}}
{{- if not .component -}}
{{- fail (printf "gateway upstream %q requires a component" $route.upstream) -}}
{{- end -}}
{{- if not (has .component (list "api" "front" "mcp-proxy" "vcs")) -}}
{{- fail (printf "gateway upstream %q targets forbidden component %q" $route.upstream .component) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
