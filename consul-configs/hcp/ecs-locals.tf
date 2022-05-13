locals {
  # config-aws-iam.tf
  ecs_service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"

  # config-aws-vpc.tf
  ap_global_name = var.ecs_ap_globals.global_prefix
  vpc_azs        = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c",
    "us-west-2d"
  ]
  unique_vpc     = "${var.cluster_cidrs.ecs_cluster.name}-${random_id.random.b64_url}"


  # config-aws-secrets_manager.tf
  secrets_values        = {
    bootstrap_token = hcp_consul_cluster.main.consul_root_token_secret_id
    gossip_key      = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
    consul_ca_cert  = base64decode(hcp_consul_cluster.main.consul_ca_file)
  }
  bootstrap_token_name  = "${local.ap_global_name}-bootstrap-token"
  gossip_key_name       = "${local.ap_global_name}-gossip-key"
  consul_ca_cert_name   = "${local.ap_global_name}-consul-ca-cert"


  # config-aws-security_groups.tf
  security_group_name          = "example-client-app-alb"
  ingress_cidr_block           = "0.0.0.0/0"
  egress_cidr_block            = "0.0.0.0/0"
  security_group_resource_name = "${local.ap_global_name}-${local.security_group_name}"


  # config-hcp-network_peering.tf
  peering_id           = "${hcp_hvn.main.hvn_id}-peering-ecs"
  peering_id_hvn_route = "${local.peering_id}-route-ecs"

  # config-consul
  acl_base                     = var.ecs_ap_globals.acl_controller.prefix
  clusters                     = {
    one = var.ecs_ap_globals.ecs_clusters.one.name
  }
  acl_prefixes = {
    cluster_one = "${local.acl_base}-${local.clusters.one}"
  }
  admin_partitions = {
    one = var.ecs_ap_globals.admin_partitions_identifiers.partition-one
  }
  consul_dc     = var.cluster_id
  log_path_base = var.ecs_ap_globals.base_cloudwatch_path.hashicups
  log_paths     = {
    private_hashicups_services = "${local.log_path_base}/${local.admin_partitions.one}/services"
  }
  launch_fargate = var.ecs_ap_globals.ecs_capacity_providers[0]
  namespace      = var.ecs_ap_globals.namespace_identifiers.global
  service_tag    = "TASK_DEFINITION"
  retry_join_url = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]


consul_service_defaults_protocols = {
    tcp = "tcp"
  }

  # reader-consul-service_intentions.tf
  tasks_count = length(keys(var.ecs_ap_globals.task_families))
  tasks = {
    private = [for t in var.hashicups_settings_private : t.name]
  }
}

