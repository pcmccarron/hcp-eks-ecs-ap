module "hashicups-tasks-private" {
  for_each                       = { for service in var.hashicups_settings_private : service.name => service }
  source                         = "registry.terraform.io/hashicorp/consul-ecs/aws//modules/mesh-task"
  version                        = "0.5.0"
  acls                           = true
  tls                            = true
  consul_image                   = "public.ecr.aws/hashicorp/consul-enterprise:1.12.2-ent"
  consul_http_addr               = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_server_ca_cert_arn      = aws_secretsmanager_secret.consul_ca_cert.arn
  gossip_key_secret_arn          = aws_secretsmanager_secret.gossip_key.arn
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
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.cluster_id}-mgw-logs"
}

locals {
  log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "mesh-gateway"
    }
  }
}

module "mesh_gateway" {
  source                             = "registry.terraform.io/hashicorp/consul-ecs/aws//modules/gateway-task"
  version                            = "0.5.0" 
  family                             = "${var.cluster_id}-mgw"
  ecs_cluster_arn                    = aws_ecs_cluster.clusters[local.clusters.one].arn
  subnets                            = module.vpc.private_subnets
  security_groups                    = [module.vpc.default_security_group_id]
  log_configuration                  = local.log_config
  retry_join                         = local.retry_join_url
  kind                               = "mesh-gateway"
  consul_datacenter                  = local.consul_dc
  consul_partition                   = local.admin_partitions.one
  enable_mesh_gateway_wan_federation = false
  tls                                = true
  consul_server_ca_cert_arn          = aws_secretsmanager_secret.consul_ca_cert.arn
  gossip_key_secret_arn              = aws_secretsmanager_secret.gossip_key.arn
  consul_image                       = "public.ecr.aws/hashicorp/consul-enterprise:1.12.2-ent"
  
 
  acls                         = true
  enable_acl_token_replication = false
  consul_http_addr             = hcp_consul_cluster.main.consul_private_endpoint_url

  lb_enabled = true
  lb_subnets = module.vpc.private_subnets
  lb_vpc_id  = module.vpc.vpc_id

  consul_ecs_image = var.consul_ecs_image
}