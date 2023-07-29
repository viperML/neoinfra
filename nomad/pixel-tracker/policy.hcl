path "kv/*" {
  capabilities = [ "list" ]
}

path "kv/data/pixel-tracker" {
  capabilities = ["read"]
}