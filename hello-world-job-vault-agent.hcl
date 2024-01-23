# This declares a job named "docs". There can be exactly one
# job declaration per job file.
job "hello-world-job-vault-agent" {
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
  group "hello-world-group-vault-agent" {
    # Specify the number of these tasks we want.
    count = 1

    network {
      port "http" {
        static = 8080
        to     = 80
      }
      port "vault" {
        static = 8100
      }
    }
      volume "vault-config" {
      type      = "host"
      source    = "vault-config"
      read_only = false
    }

    # The service block tells Nomad how to register this service
    # with Consul for service discovery and monitoring.
    service {
      name = "hello-world-vault-agent"
      port = "http"
      check {
        name     = "hello-world-vault-agent"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Create an individual task (unit of work).
    task "hello-world-httpd-server" {
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image = "httpd"
        ports = ["http"]
        #This mounts the task directory to the apache htdocs directory
        mount {
          type   = "bind"
          source = "local"
          target = "/usr/local/apache2/htdocs"
        }
      }
      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }

    task "hello-world-vault-agent" {
      driver = "docker"
      config {
        image = "hashicorp/vault"
        ports = ["vault"]
        args = [
          "agent", "-config=/vault/config/agent/agent-config.hcl", "-log-level=debug"
        ]
      }
        volume_mount {
        volume      = "vault-config"
        destination = "/vault/config"
      }

      
       resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }
  }
}

#nomad job run hello-world-job-2-job.hcl




