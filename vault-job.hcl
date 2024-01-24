# This declares a job named "docs". There can be exactly one
# job declaration per job file.
job "vault-job" {
  # Specify this job should run in the region named "us". Regions
  # are defined by the Nomad servers' configuration.
  region = "us"

  datacenters = ["bbarkhouse"]

  type = "service"

  # Specify this job to have rolling updates, two-at-a-time, with
  # 30 second intervals.
  update {
    stagger      = "30s"
    max_parallel = 2
  }


  # A group defines a series of tasks that should be co-located
  # on the same client (host). All tasks within a group will be
  # placed on the same host.
  group "vault-group" {
    # Specify the number of these tasks we want.
    count = 1
    volume "vault-data" {
      type      = "host"
      source    = "vault-data"
      read_only = false
    }
    volume "vault-config" {
      type      = "host"
      source    = "vault-config"
      read_only = false
    }

    network {
      port "http" {
        static = 8200
      }
    }

    # The service block tells Nomad how to register this service
    # with Consul for service discovery and monitoring.
    service {
      name = "vault-server"
      port = "http"
      check {
        name     = "vault"
        type     = "http"
        path     = "/v1/sys/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Create an individual task (unit of work).
    task "vault-server" {
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image      = "hashicorp/vault:1.15.0"
        ports      = ["http"]
        entrypoint = ["/bin/sh", "/vault/config/startup.sh"]
      }
      volume_mount {
        volume      = "vault-data"
        destination = "/vault/data"
      }
      volume_mount {
        volume      = "vault-config"
        destination = "/vault/config"
      }

      #Read the Vault UNSEAL_KEY Nomad Variable and place into the task as an environment variable the startup.sh script can access to unseal Vault.
      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/vault-job" }}
UNSEAL_KEY = {{ .UNSEAL_KEY }}
{{ end }}
EOH
        destination = "secrets/env"
        env         = true
      }

      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
      env {
        VAULT_ADDR = "http://${NOMAD_ADDR_http}"
      }
    }
  }
}
#nomad job run vault-job.hcl