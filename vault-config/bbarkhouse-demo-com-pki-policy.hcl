path "pki*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "kv/data/default/hello-world-job/*" {
  capabilities = ["read"]
}

path "kv/data/default/hello-world-job" {
  capabilities = ["read"]
}

path "kv/metadata/default/*" {
  capabilities = ["list"]
}
