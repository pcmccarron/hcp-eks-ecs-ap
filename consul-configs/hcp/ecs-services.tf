resource "aws_ecs_service" "private_services" {
  for_each = data.aws_ecs_task_definition.private_tasks

  desired_count          = 1
  enable_execute_command = true
  cluster                = aws_ecs_cluster.clusters[local.clusters.one].arn
  launch_type            = local.launch_fargate
  propagate_tags         = local.service_tag
  name                   = each.value.family
  task_definition        = each.value.arn
  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}

