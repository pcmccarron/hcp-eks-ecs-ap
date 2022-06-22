resource "aws_cloudwatch_log_group" "acl_log_group" {
  name = "${var.cluster_id}-acl-controller-logs"
}

module "acl_controller" {
  source   = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version  = "0.5.0"
  subnets                           = module.vpc.private_subnets
  consul_server_http_addr           = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  region                            = var.region
  consul_partitions_enabled         = var.ecs_ap_globals.enable_admin_partitions.enabled
  consul_partition                  = local.admin_partitions.one
  ecs_cluster_arn                   = aws_ecs_cluster.clusters[local.clusters.one].arn
  name_prefix                       = "${local.acl_base}"

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.acl_log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "acl-controller"
    }
  }
  consul_ecs_image = var.consul_ecs_image
}