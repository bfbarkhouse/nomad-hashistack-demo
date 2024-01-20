resource "vault_jwt_auth_backend_role" "bbarkhouse-demo-hello-world-2" {
  backend         = "jwt-nomad" #This assumes you've already configured a jwt auth backend for Nomad workload identity. See this tutorial: https://developer.hashicorp.com/nomad/tutorials/integrate-vault/vault-acl
  role_name       = "bbarkhouse-demo-hello-world-2"
  role_type       = "jwt"
  token_type = "service"
  token_policies  = ["bbarkhouse-demo-hello-world-2-policy"]
  token_period = 1800
  token_explicit_max_ttl = 0

  bound_audiences = ["vault.io"]
  bound_claims = {
    nomad_namespace = "default"
    nomad_job_id = "hello-world-job-2"
  }
  user_claim      = "/nomad_job_id"
  user_claim_json_pointer =  true
  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id = "nomad_job_id"
    nomad_task = "nomad_task"
  }
}
#resource pki secrets engine
resource "vault_mount" "pki" {
  path                      = "pki-bfbarkhouse"
  type                      = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 525600
}
#Configure a CA certificate and private key.
resource "vault_pki_secret_backend_root_cert" "bfbarkhouse-root" {
  depends_on            = [vault_mount.pki]
  backend               = vault_mount.pki.path
  type                  = "internal"
  common_name           = "Root CA"
  ttl                   = "315360000"
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = "My OU"
  organization          = "My organization"
}
#Update the CRL location and issuing certificates.
resource "vault_pki_secret_backend_config_urls" "bfbarkhouse-root-urls" {
  backend = vault_mount.pki.path
  issuing_certificates = [
    "http://10.0.0.194:8200/v1/pki/ca",
  ]
  crl_distribution_points = [
    "http://10.0.0.194:8200/v1/pki/crl"
  ]
}
#resource pki role
resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.pki.path
  name             = "bfbarkhouse-com-demo-pki-role"
  ttl              = 4320
  allow_ip_sans    = true
  key_type         = "rsa"
  key_bits         = 4096
  allowed_domains  = ["bfbarkhouse-demo.com"]
  allow_subdomains = true
}
#resource token policy
resource "vault_policy" "bbarkhouse-demo-hello-world-2-policy" {
  name = "bbarkhouse-demo-hello-world-2-policy"

  policy = <<EOT
path "pki-bfbarkhouse*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "kv/data/default/hello-world-job-2/*" {
  capabilities = ["read"]
}

path "kv/data/default/hello-world-job-2" {
  capabilities = ["read"]
}

path "kv/metadata/default/*" {
  capabilities = ["list"]
}
EOT
}
#kv secrets engine
# resource "vault_mount" "hello-world-job-2" {
#   path        = "hello-world-job-2"
#   type        = "kv-v2"
#   options = {
#     version = "2"
#     type    = "kv-v2"
#   }
# }
#write secret to kv
resource "vault_kv_secret_v2" "httpd-secret" {
  mount                      = "kv"
  name                       = "/default/hello-world-job-2"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
  {
    httpd_secret       = "nomad_used_workload_identity_to_pull_this_secret_again"
  }
  )
}
resource "nomad_job" "hello-world-job-2" {
  jobspec = file("../hello-world-job-2.hcl")
}