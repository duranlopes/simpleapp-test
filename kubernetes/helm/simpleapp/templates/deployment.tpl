apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "simpleapp.fullname" . }}
  labels:
    {{- include "simpleapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "simpleapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "simpleapp.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "simpleapp.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      {{- with .Values.image.pullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: simpleapp
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          ports:
            - name: http
              containerPort: 8008
              protocol: TCP
          env:
            - name: ELASTIC_APM_ENABLED
              value: {{ .Values.apm.enabled | quote }}
            - name: ELASTIC_APM_SERVICE_NAME
              value: {{ .Values.apm.serviceName | quote }}
            - name: ELASTIC_APM_SERVER_URL
              value: {{ .Values.apm.serverUrl | quote }}
            {{- if .Values.apm.existingSecret }}
            - name: ELASTIC_APM_SECRET_TOKEN
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.apm.existingSecret }}
                  key: {{ .Values.apm.secretKey }}
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "simpleapp.fullname" . }}
          livenessProbe:
            {{- toYaml .Values.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.readinessProbe | nindent 12 }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
