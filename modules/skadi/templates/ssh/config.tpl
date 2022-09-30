Host *
{{- if or .User.GOOS "none" | eq "windows" }}
{{- if .User.StepBasePath }}
	Include "{{ .User.StepBasePath | replace "\\" "/" | trimPrefix "C:" }}/ssh/includes"
{{- else }}
	Include "{{ .User.StepPath | replace "\\" "/" | trimPrefix "C:" }}/ssh/includes"
{{- end }}
{{- else }}
{{- if .User.StepBasePath }}
	Include "{{.User.StepBasePath}}/ssh/includes"
{{- else }}
	Include "{{.User.StepPath}}/ssh/includes"
{{- end }}
{{- end }}