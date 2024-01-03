# This declares a job named "docs". There can be exactly one
# job declaration per job file.
job "hello-world-job" {
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
  group "hello-world-group" {
    # Specify the number of these tasks we want.
    count = 1

    network {
      port "http" {
        static = 8080
        to = 80
      }
    }

    # Create an individual task (unit of work).
    task "hello-world-server" {
      driver = "docker"

      # Configuration is specific to each driver.
      config {
        image = "httpd"
        ports = ["http"]
      }
      vault {}
       template {
    data = <<EOF
      HTTPD_SECRET = "{{with secret "kv/data/default/hello-world-job"}}{{.Data.data.httpd_secret}}{{end}}"
    EOF
          destination = "secrets/file.env"
        env         = true
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




