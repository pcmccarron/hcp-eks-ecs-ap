resource "hcp_aws_network_peering" "eks" {
  peering_id      = "${hcp_hvn.main.hvn_id}-peering-eks"
  hvn_id          = hcp_hvn.main.hvn_id
  peer_vpc_id     = module.eks-vpc.vpc_id
  peer_account_id = data.aws_caller_identity.current.account_id
  peer_vpc_region = var.region
}

resource "aws_vpc_peering_connection_accepter" "eks-peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.eks.provider_peering_id
  auto_accept               = true
}

resource "hcp_hvn_route" "eks-peering_route" {
  depends_on       = [aws_vpc_peering_connection_accepter.eks-peer]
  hvn_link         = hcp_hvn.main.self_link
  hvn_route_id     = "${hcp_hvn.main.hvn_id}-peering-route-eks"
  destination_cidr = module.eks-vpc.vpc_cidr_block
  target_link      = hcp_aws_network_peering.eks.self_link
}

resource "aws_route" "eks-peering" {
  route_table_id            = module.eks-vpc.public_route_table_ids[0]
  destination_cidr_block    = hcp_hvn.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-peer.vpc_peering_connection_id
}

resource "aws_route" "eks-peering2" {
  route_table_id            = module.eks-vpc.private_route_table_ids[0]
  destination_cidr_block    = hcp_hvn.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.eks-peer.vpc_peering_connection_id
}

locals {
  ingress_consul_rules = [
    {
      description = "Consul LAN Serf (tcp)"
      port        = 8301
      protocol    = "tcp"
    },
    {
      description = "Consul LAN Serf (udp)"
      port        = 8301
      protocol    = "udp"
    },
  ]

  # If a list of security_group_ids was provided, construct a rule set.
  hcp_consul_security_groups = flatten([
    for _, sg in var.security_group_ids : [
      for _, rule in local.ingress_consul_rules : {
        security_group_id = sg
        description       = rule.description
        port              = rule.port
        protocol          = rule.protocol
      }
    ]
  ])
}

resource "aws_security_group" "hcp_consul" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name_prefix = "hcp_consul"
  description = "HCP Consul security group"
  vpc_id      = module.eks-vpc.vpc_id
}

# If no security_group_ids were provided, use the new security_group.
resource "aws_security_group_rule" "hcp_consul_new_grp" {
  count             = length(var.security_group_ids) == 0 ? length(local.ingress_consul_rules) : 0
  description       = local.ingress_consul_rules[count.index].description
  protocol          = local.ingress_consul_rules[count.index].protocol
  security_group_id = aws_security_group.hcp_consul[0].id
  cidr_blocks       = [var.hvn_cidr_block]
  from_port         = local.ingress_consul_rules[count.index].port
  to_port           = local.ingress_consul_rules[count.index].port
  type              = "ingress"
}

# If no security_group_ids were provided, allow egress on the new security_group.
resource "aws_security_group_rule" "allow_all_egress" {
  count             = length(var.security_group_ids) == 0 ? 1 : 0
  description       = "Allow egress access to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.hcp_consul[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

# If no security_group_ids were provided, allow self ingress on the new security_group.
resource "aws_security_group_rule" "allow_self" {
  count             = length(var.security_group_ids) == 0 ? 1 : 0
  description       = "Allow members of this security group to communicate over all ports"
  protocol          = "-1"
  security_group_id = aws_security_group.hcp_consul[0].id
  self              = true
  from_port         = 0
  to_port           = 0
  type              = "ingress"
}