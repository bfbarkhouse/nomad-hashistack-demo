# This declares a job named "docs". There can be exactly one
# job declaration per job file.
job "prom-job" {
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
  group "prom-group" {
    # Specify the number of these tasks we want.
    count = 1
    volume "prom-config" {
      type      = "host"
      source    = "prometheus-config"
      read_only = false
    }

    network {
      port "http" {
        static = 9090
      }
    }

    # The service block tells Nomad how to register this service
    # with Consul for service discovery and monitoring.
    service {
      port = "http"
      check {
        name     = "prometheus"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Create an individual task (unit of work).
    task "prometheus-server" {
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image = "prom/prometheus"
        ports = ["http"]
      }
      volume_mount {
        volume      = "prom-config"
        destination = "/etc/prometheus"
      }
      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }
  }
}
#nomad job start prom-job.hcl




