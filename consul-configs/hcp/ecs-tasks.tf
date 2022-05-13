module "hashicups-tasks-private" {
  for_each                       = { for service in var.hashicups_settings_private : service.name => service }
  source                         = "registry.terraform.io/hashicorp/consul-ecs/aws//modules/mesh-task"
  version                        = "0.4.1"
  acls                           = true
  tls                            = true
  consul_image                   = var.ecs_ap_globals.consul_enterprise_image.enterprise_latest
  consul_server_ca_cert_arn      = aws_secretsmanager_secret.consul_ca_cert.arn
  gossip_key_secret_arn          = aws_secretsmanager_secret.gossip_key.arn
  consul_client_token_secret_arn = module.acl_controller[local.clusters.one].client_token_secret_arn
  acl_secret_name_prefix         = local.acl_prefixes.cluster_one
  retry_join                     = local.retry_join_url
  consul_datacenter              = local.consul_dc
  consul_partition               = local.admin_partitions.one
  consul_namespace               = local.namespace
  family                         = each.value.name
  port                           = each.value.portMappings[0].hostPort
  upstreams                      = length(each.value.upstreams) > 0 ? each.value.upstreams : []
  log_configuration = {
    logDriver = var.ecs_ap_globals.cloudwatch_config.log_driver
    options = {
      awslogs-stream-prefix = each.value.name
      awslogs-region        = var.region
      awslogs-create-group  = var.ecs_ap_globals.cloudwatch_config.create_groups
      awslogs-group         = "${local.log_paths.private_hashicups_services}/${each.value.name}"
    }
  }
  container_definitions = [{
    essential   = true
    cpu         = 0
    mountPoints = []
    volumesFrom = []
    name        = each.value.name
    image       = each.value.image
    logConfiguration = {
      logDriver = var.ecs_ap_globals.cloudwatch_config.log_driver
      options = {
        awslogs-stream-prefix = each.value.name
        awslogs-region        = var.region
        awslogs-create-group  = var.ecs_ap_globals.cloudwatch_config.create_groups
        awslogs-group         = "${local.log_paths.private_hashicups_services}/${each.value.name}"
      }
    }
    # Create the environment variables so that the frontend is loaded with the environment variable needed to communicate with public-api
    environment = concat(each.value.environment,
      [{
        name  = "NAME"
        value = "${var.ecs_ap_globals.global_prefix}-${each.value.name}"
    }])
    portMappings = [{
      containerPort = each.value.portMappings[0].containerPort
      hostPort      = each.value.portMappings[0].hostPort
      protocol      = each.value.portMappings[0].protocol
    }]

  }]
  task_role = {
    id  = each.value.name
    arn = aws_iam_role.hashicups[var.ecs_ap_globals.ecs_clusters.one.name].arn
  }
  additional_execution_role_policies = [
    aws_iam_policy.hashicups.arn
  ]
}