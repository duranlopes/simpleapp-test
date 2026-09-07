apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "simpleapp.fullname" . }}
  labels:
    {{- include "simpleapp.labels" . | nindent 4 }}
data:
  Code: {{ .Values.config.code | quote }}
