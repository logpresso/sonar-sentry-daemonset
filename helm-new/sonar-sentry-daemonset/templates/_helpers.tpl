{{/*
Expand the name of the chart.
*/}}
{{- define "sonar-sentry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sonar-sentry.fullname" -}}
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
{{- define "sonar-sentry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sonar-sentry.labels" -}}
helm.sh/chart: {{ include "sonar-sentry.chart" . }}
{{ include "sonar-sentry.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sonar-sentry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sonar-sentry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sonar-sentry.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "sa-sonar-sentry" .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate a unique identifier for each DaemonSet pod.
*/}}
{{- define "sonar-sentry.guidPrefix" -}}
{{- $prefixDefault := printf "%s-" .Release.Name -}}
{{- default $prefixDefault .Values.sonar.guidPrefix -}} 
{{- end -}}

{{/*
Get deployment type in a case-insensitive way
*/}}
{{- define "sonar-sentry.deploymentType" -}}
{{- $type := .Values.sonar.deploymentType | lower -}}
{{- if eq $type "daemonset" -}}
DaemonSet
{{- else if eq $type "deployment" -}}
Deployment
{{- else -}}
Deployment
{{- end -}}
{{- end -}}