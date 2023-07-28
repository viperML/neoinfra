path "kv/*" {
  capabilities = [ "list" ]
}

path "kv/data/obsidian" {
  capabilities = ["read"]
}