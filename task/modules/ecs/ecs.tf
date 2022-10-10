# resources needed to enble https access to the hello-world app are disabled by default
# and require the user to enable via the enable_ssl input variable
# this is because aws charges $400+ to run their certificate authority

locals {
  depends = var.enable_ssl ? "\"aws_alb_listener.http_redirect[0]\", \"aws_alb_listener.https[0]\"" : "aws_alb_listener.http[0]"
}

data "aws_region" "current" {}

# ecs roles
resource "aws_iam_role" "ecs_task_role" {
  name = "devops-tech-task-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { "Service" : "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "devops-tech-task-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { "Service" : "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ecs fargate cluster
resource "aws_ecs_cluster" "self" {
  name = "devops-tech-task"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    role = "ecs"
    name = "devops-tech-task"
  }
}

resource "aws_ecs_task_definition" "self" {
  family                   = "devops-tech-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name      = "hello-world"
    image     = "strm/helloworld-http"
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = 80
    }]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = "/devops-tech-task"
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "image"
      }
    }
  }])

  tags = {
    role = "ecs"
    name = "devops-tech-task"
  }
}

resource "aws_cloudwatch_log_group" "self" {
  name              = "/devops-tech-task"
  retention_in_days = 1

  tags = {
    role = "ecs"
    name = "devops-tech-task"
  }
}

resource "aws_ecs_service" "self" {
  name                               = "devops-tech-task-service"
  cluster                            = aws_ecs_cluster.self.id
  task_definition                    = aws_ecs_task_definition.self.arn
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.self.arn
    container_name   = "hello-world"
    container_port   = 80
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [local.depends]

  tags = {
    role = "ecs"
    name = "devops-tech-task"
  }
}
