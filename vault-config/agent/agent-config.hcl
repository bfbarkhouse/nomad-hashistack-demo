pid_file = "/vault/config/pidfile"

vault {
  address = "http://10.0.0.194:8200"
}

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path                   = "/secrets/roleID"
      secret_id_file_path                 = "/secrets/secretID"
      remove_secret_id_file_after_reading = false
    }
  }

  sink "file" {
    config = {
      path = "/vault/config/agent/approleToken"
    }
  }
}

cache {
  use_auto_auth_token = true
}

listener "tcp" {
  address     = "0.0.0.0:8100"
  tls_disable = true
}

template {
  source      = "/vault/config/agent/kv-secret.ctmpl"
  destination = "/alloc/data/vault-secret.txt"
}