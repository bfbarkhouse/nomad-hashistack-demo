job "jboss-host-job" {
  region      = "us"
  datacenters = ["dc1"]
  #Node pools are a way to group clients and segment infrastructure into logical units that can be targeted by jobs for a strong control over where allocations are placed.
  node_pool   = "jboss-dc-01"
  type        = "service"

  group "jboss-host-group" {
    # Specify the number of these tasks we want.
    count = 3
    volume "jboss-host" {
      type      = "host"
      source    = "jboss-host"
      read_only = false
    }

    network {
      port "http" {
        static = 8080
      }
      port "https" {
        static = 8443
      }
      port "api" {
        static = 9999
      }
      port "mgmt" {
        static = 9990
      }
    }
    task "jboss-host" {
      driver = "exec"
      config {
        command = "${EAP_HOME}/bin/domain.sh"
        args    = ["--host-config=${EAP_HOME}/domain/configuration/host-slave.xml", "-Djboss.domain.master.address=${DOMAIN_IP}, -Djboss.bind.address=${NOMAD_IP_mgmt}"]
        ports   = ["http", "https", "api", "mgmt"]
      }

      volume_mount {
        volume      = "jboss-host"
        destination = "${EAP_HOME}"
      }
      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
      
      #Using a template to find the address of the host running the jboss-domain service
      template {
        data = <<EOF
        {{ range nomadService "jboss-domain" }}
        DOMAIN_IP = "{{ .Address }}"
        {{end}}
        EOF
        destination = "local/env"
        env = true
      }
      env {
        EAP_HOME = "/opt/rh/eap7/root/usr/share/wildfly/"
      }
    }
  }
}
#nomad job start jboss-hosts.nomad.hcl
