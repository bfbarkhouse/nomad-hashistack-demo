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
        to     = 80
      }
    }

    # The service block tells Nomad how to register this service
    # with Consul for service discovery and monitoring.
    service {
      name = "hello-world"
      port = "http"
      check {
        name     = "hello-world"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Create an individual task (unit of work).
    task "hello-world-server" {
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
      vault {
        role = "bbarkhouse-demo-com-pki" #This is a unique JWT role that allows this task to issue certificates from the bbarkhouse-demo-com PKI role in Vault 
      }
      #This template pulls a secret from Vault and creates an environment variable
      template {
        change_mode = "restart"
        data        = <<EOF
      HTTPD_SECRET = "{{with secret "kv/data/default/hello-world-job"}}{{.Data.data.httpd_secret}}{{end}}"
    EOF
        destination = "secrets/env"
        env         = true
      }
      #This template pulls a secret from Vault and constructs a new index.html containing the secret
      template {
        change_mode = "restart"
        data        = <<EOF
      <html><body><h1>{{with secret "kv/data/default/hello-world-job"}}{{.Data.data.httpd_secret}}{{end}}</h1></body></html>
    EOF
        destination = "local/index.html"
      }
      #This template issues a PKI certificate from Vault and puts it in the task directory      
      template {
        change_mode = "restart"
        data        = <<EOF
      {{ with secret "pki/issue/bbarkhouse-demo-com" "common_name=hello-world.bbarkhouse-demo.com" "ttl=24h" "alt_names=localhost"}}
{{ .Data.certificate }}
{{ end }}
    EOF
        destination = "local/hello-world.crt"
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




