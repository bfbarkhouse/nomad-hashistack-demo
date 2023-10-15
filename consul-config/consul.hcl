datacenter  = "bbarkhouse"
data_dir    = "/opt/consul"
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
ui          = true
server      = true
encrypt     = "AfU80fM75pmRKMaBhNw1RZeS9yACvBu/EbYcv767Z4g="

bootstrap_expect = 1
telemetry {
  disable_hostname = true
  prometheus_retention_time = "12h"
}