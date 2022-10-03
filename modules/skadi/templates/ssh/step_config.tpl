Match exec "step ssh check-host{{- if .User.Context }} --context {{ .User.Context }}{{- end }} %h"
{{- if .User.User }}
	User {{.User.User}}
{{- end }}
{{- if or .User.GOOS "none" | eq "windows" }}
	UserKnownHostsFile "{{.User.StepPath}}\ssh\known_hosts"
	ProxyCommand C:\Windows\System32\cmd.exe /c step ssh proxycommand{{- if .User.Context }} --context {{ .User.Context }}{{- end }} %r %h %p --provisioner="Google"
{{- else }}
	UserKnownHostsFile "{{.User.StepPath}}/ssh/known_hosts"
	ProxyCommand step ssh proxycommand{{- if .User.Context }} --context {{ .User.Context }}{{- end }} SET_EMAIL %h %p --provisioner="Google"
{{- end }}
