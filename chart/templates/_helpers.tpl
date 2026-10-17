{{/*
Expand the name of the chart.
*/}}
{{- define "sa-p5.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sa-p5.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sa-p5.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sa-p5.labels" -}}
helm.sh/chart: {{ include "sa-p5.chart" . }}
{{ include "sa-p5.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sa-p5.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sa-p5.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sa-p5.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sa-p5.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Practica 10: variables de entorno de OpenTelemetry de un servicio
instrumentado. Se define aqui (chart padre) y la incluyen los subcharts
api-gateway, pedidos-service y productos-service con
  include "sa-p5.otelEnv" .
(Helm comparte el espacio de nombres de plantillas entre padre y subcharts.)
Con otel.enabled=false no agrega nada: el cluster de la Practica 8, que no
carga values-p10.yaml, queda igual.

Van en el spec del pod y no en el ConfigMap a proposito: extraEnv lleva la
falla inducida (FALLA_TASA_ERROR...), y solo un cambio en el pod template
hace que Argo Rollouts despliegue una revision canary.
*/}}
{{- define "sa-p5.otelEnv" -}}
{{- if and .Values.otel .Values.otel.enabled }}
- name: OTEL_SERVICE_NAME
  value: {{ .Chart.Name | quote }}
- name: OTEL_RESOURCE_ATTRIBUTES
  value: {{ printf "service.version=%s,deployment.environment=%s" (toString .Values.image.tag) (.Values.otel.environment | default "sa-p9") | quote }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ required "otel.endpoint es obligatorio con otel.enabled" .Values.otel.endpoint | quote }}
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: http/protobuf
- name: OTEL_METRIC_EXPORT_INTERVAL
  value: {{ .Values.otel.metricExportIntervalMs | default 10000 | quote }}
- name: OTEL_SEMCONV_STABILITY_OPT_IN
  value: http
{{- end }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
