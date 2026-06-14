locals {
  reserved_public_ports = toset([22, 80, 443, 8443, 51820])

  service_public_ports = sort(distinct([
    for port in var.public_ports :
    port if !contains(local.reserved_public_ports, port)
  ]))

  public_port_priorities = {
    for idx, port in local.service_public_ports :
    tostring(port) => 140 + idx
  }
}
