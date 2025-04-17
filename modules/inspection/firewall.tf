# firewall policy
resource "aws_networkfirewall_firewall_policy" "firewall_policy" {
  name = "firewall-policy"

  firewall_policy {
    #stateless_default_actions          = ["aws:forward_to_sfe"]
    #stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]

    # stateful_rule_group_reference {
    #   resource_arn = aws_networkfirewall_rule_group.fw_rules_group.arn
    # }
  }
}

# statefull firewall rules group
# resource "aws_networkfirewall_rule_group" "fw_rules_group" {
#   name     = "inspection-fw-stateful-rules"
#   capacity = 10000
#   type     = "STATEFUL"

#   rule_group {
#     rules_source {
#       rules_string = file("${path.module}/data/inspection_firewall.rules")
#     }
#   }
# }

# inspection AWS Network Firewall
resource "aws_networkfirewall_firewall" "inspection_firewall" {
  name                = "${var.name}-inspection-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.firewall_policy.arn
  vpc_id              = aws_vpc.inspection_vpc.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall_subnets
    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = {
    Name = "${var.name}-inspection-firewall"
  }
}

# aws firewall cloud watch log group
resource "aws_cloudwatch_log_group" "nf_flow_logs" {
  name              = "/aws/${var.name}-network-firewall/flow-logs"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "nf_alert_logs" {
  name              = "/aws/${var.name}-network-firewall/alert-logs"
  retention_in_days = 14
}

resource "aws_networkfirewall_logging_configuration" "nf_logging_config" {
  firewall_arn = aws_networkfirewall_firewall.inspection_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.nf_flow_logs.name
      }
    }

    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.nf_alert_logs.name
      }
    }
  }
}
