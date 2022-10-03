{
	"type": "{{ .Type }}",
	"keyId": "{{ .KeyID }}",
	"principals": ["{{ .Token.email }}"],
    "extensions": {{ toJson .Extensions }},
    "criticalOptions": {{ toJson .CriticalOptions }}
}
