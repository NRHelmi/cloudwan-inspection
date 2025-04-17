# Global Network
resource "aws_networkmanager_global_network" "global_network" {
  description = "Global Network - POC"

  tags = {
    Name = "Global Network - POC"
  }
}

# Core Network
resource "aws_networkmanager_core_network" "core_network" {
  description       = "Core Network - POC"
  global_network_id = aws_networkmanager_global_network.global_network.id

  create_base_policy = false

  tags = {
    Name = "Core Network - POC"
  }
}

# policies
data "aws_networkmanager_core_network_policy_document" "core_network_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["4200000000-4294967294"]

    edge_locations {
      asn      = "4200000000"
      location = "eu-west-3"
    }
  }

  # inspection network function
  network_function_groups {
    name                          = "POCInspectionNFG"
    require_attachment_acceptance = true
  }

  # cloudwan segments
  segments {
    name                          = "SegA"
    isolate_attachments           = false
    require_attachment_acceptance = true
  }

  segments {
    name                          = "SegB"
    isolate_attachments           = false
    require_attachment_acceptance = true
  }

  # segments actions
  segment_actions {
    action  = "send-via"
    segment = "SegA"
    mode    = "single-hop"
    when_sent_to {
      segments = [
        "SegB"
      ]
    }
    via {
      network_function_groups = ["POCInspectionNFG"]
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "SegB"
    mode    = "single-hop"
    when_sent_to {
      segments = [
        "SegA"
      ]
    }
    via {
      network_function_groups = ["POCInspectionNFG"]
    }
  }

  # attachment policies
  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "CWAttach"
      value    = "POCInspectionNFG"
    }

    action {
      add_to_network_function_group = "POCInspectionNFG"
    }
  }

  attachment_policies {
    rule_number     = 101
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "CWAttach"
      value    = "SegA"
    }

    action {
      association_method = "constant"
      segment            = "SegA"
    }
  }

  attachment_policies {
    rule_number     = 102
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "CWAttach"
      value    = "SegB"
    }

    action {
      association_method = "constant"
      segment            = "SegB"
    }
  }
}

# core network policy attachement
resource "aws_networkmanager_core_network_policy_attachment" "poc_core_network_policy_attachement" {
  core_network_id = aws_networkmanager_core_network.core_network.id
  policy_document = data.aws_networkmanager_core_network_policy_document.core_network_policy.json
}
