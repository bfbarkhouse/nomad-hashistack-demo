terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "2.1.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.24.0"
    }
  }
}
provider "nomad" {
  # Configuration options
  address     = "http://10.0.0.194:4646"
  skip_verify = true
  #secret_id   = Set in the env var NOMAD_TOKEN
}

provider "vault" {
  # Configuration options
  address         = "http://10.0.0.194:8200"
  skip_tls_verify = true
  #I'm using approle auth but you can manually set any token you want using the config below
  #token           = Set in env var VAULT_TOKEN
  #approle auth
  skip_child_token = true # https://stackoverflow.com/questions/73034161/permission-denied-on-vault-terraform-provider-token-creation
  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id   = var.vault_role_id #Set in env var TF_VAR_vault_role_id
      secret_id = var.vault_role_secret_id #Set in env var TF_VAR_vault_role_secret_id
    }
  }
}