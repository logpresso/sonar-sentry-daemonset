{{/*
Expand the name of the chart.
*/}}
{{- define "sonar-sentry-daemonset.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sonar-sentry-daemonset.fullname" -}}
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
{{- define "sonar-sentry-daemonset.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sonar-sentry-daemonset.labels" -}}
helm.sh/chart: {{ include "sonar-sentry-daemonset.chart" . }}
{{ include "sonar-sentry-daemonset.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sonar-sentry-daemonset.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sonar-sentry-daemonset.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sonar-sentry-daemonset.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sonar-sentry-daemonset.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate a unique identifier for each DaemonSet pod.
*/}}
{{- define "sonar-sentry-daemonset.guidPrefix" -}}
{{- $prefixDefault := printf "%s-" .Release.Name -}}
{{- default $prefixDefault .Values.sonar.guidPrefix -}} 
{{- end -}}