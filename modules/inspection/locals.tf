locals {
  fw_vpc_endpoints = { for endpoint in aws_networkfirewall_firewall.inspection_firewall.firewall_status[0].sync_states[*].attachment[0] :
    endpoint.subnet_id => endpoint.endpoint_id
  }
}
