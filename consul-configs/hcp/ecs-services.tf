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
    security_groups  = [aws_security_group.frontend_lb.id]
    assign_public_ip = true
  }
  dynamic "load_balancer" {
    # Only configure load balancing targets for tasks that require it, namely, any entity present in the local.entities list that filters the required tasks.
    # The for_each evaluates true when the container name and task definition match each other.
    for_each = { for e in local.load_balancer_public_apps_config : e.container_name => e if each.value.task_definition == e.container_name }
    content {
      container_name   = each.value.task_definition
      container_port   = load_balancer.value.container_port
      target_group_arn = load_balancer.value.target_group
    }
  }
}
