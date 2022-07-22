resource "aws_iam_role" "hashicups" {
  for_each = { for cluster in var.ecs_ap_globals.ecs_clusters : cluster.name => cluster }
  name     = "${var.iam_role_name}-${each.value.name}"
  path     = "/consul-ecs/"
  tags     = {
              "consul.hashicorp.com.service-name" = "${each.value.name}" 
              "consul.hashicorp.com.namespace" = "default"
            }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = var.iam_effect.allow
        Principal = {
          Service = var.iam_service_principals.ecs_tasks
        }
        Action = var.iam_action_type.assume_role
      },
      {
        Effect = var.iam_effect.allow
        Principal = {
          "AWS" = [local.ecs_service_role]
        }
        Action = var.iam_action_type.assume_role
      },
      {
        Effect = var.iam_effect.allow
        Principal = {
          Service = var.iam_service_principals.ecs
        }
        Action = var.iam_action_type.assume_role
      },
    ]
  })
}

resource "aws_iam_policy" "hashicups" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = var.iam_actions_allow.secrets_manager_get
        Effect = var.iam_effect.allow
        Resource = [
          aws_secretsmanager_secret.gossip_key.arn,
          aws_secretsmanager_secret.bootstrap_token.arn,
          aws_secretsmanager_secret.consul_ca_cert.arn,
        ]
      },
      {
        Action   = var.iam_actions_allow.logging_create_and_put
        Effect   = var.iam_effect.allow
        Resource = ["*"]
  }]
  })
}

resource "aws_iam_role_policy_attachment" "hashicups" {
  for_each   = aws_iam_role.hashicups
  policy_arn = aws_iam_policy.hashicups.arn
  role       = each.value.name
}

resource "aws_iam_policy" "aws-ecs-exec-perms" {
  for_each    = { for service in var.hashicups_settings_private : service.name => service }
  name        = "${each.value.name}-ecs-exec"
  path        = "/"
  description = "${each.value.name} execution policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}