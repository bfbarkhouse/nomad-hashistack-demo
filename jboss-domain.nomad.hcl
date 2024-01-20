job "jboss-domain-job" {
  region      = "us"
  datacenters = ["dc1"]
  #Node pools are a way to group clients and segment infrastructure into logical units that can be targeted by jobs for a strong control over where allocations are placed.
  node_pool   = "jboss-dc-01"
  type        = "service"

  group "jboss-domain-group" {
    # Specify the number of these tasks we want.
    count = 1
    volume "jboss-dc" {
      type      = "host"
      source    = "jboss-dc"
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

    task "jboss-domain" {
      driver = "exec"
      config {
        command = "${EAP_HOME}/bin/domain.sh"
        args    = ["--host-config=${EAP_HOME}/domain/configuration/host-master.xml", "-Djboss.bind.address.management=${NOMAD_IP_mgmt}"]
        ports   = ["http", "https", "api", "mgmt"]
      }
      #Exposing the jboss domain as a service to be looked up by the jboss hosts
      service {
        name = "jboss-domain"
        provider = "nomad"
        address = "${NOMAD_IP_mgmt}"
      }

      volume_mount {
        volume      = "jboss-dc"
        destination = "${EAP_HOME}"
      }
      # Specify the maximum resources required to run the task.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB
      }
      env {
        EAP_HOME = "/opt/rh/eap7/root/usr/share/wildfly/"
      }
    }
  }
}
#nomad job run jboss-domain.nomad.hcl
