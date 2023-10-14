# This declares a job named "docs". There can be exactly one
# job declaration per job file.
job "consul-job" {
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
  group "consul-group" {
    # Specify the number of these tasks we want.
    count = 1
    volume "consul-config" {
      type      = "host"
      source    = "consul-config"
      read_only = false
    }

    network {
      port "http" {
        static = 8500
      }
      port "dns" {
        static = 8600
      }
    }

    # Create an individual task (unit of work).
    task "consul-server" {
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image = "hashicorp/consul"
        ports = ["http", "dns"]
        args = [
          "agent", "-config-dir=/etc/consul.d"
        ]
      }
      volume_mount {
        volume      = "consul-config"
        destination = "/etc/consul.d"
      }

      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
    }
  }
}
#nomad job start consul-job.hcl




