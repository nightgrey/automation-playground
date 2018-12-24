provider "aws" {
  region = "eu-central-1"
}

# Networking
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/24"

  tags {
    project = "${var.project-name}"
  }
}

resource "aws_subnet" "subnet" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    project = "${var.project-name}"
  }
}

resource "aws_internet_gateway" "internet-gatway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    project = "${var.project-name}"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    project = "${var.project-name}"
  }
}

resource "aws_route" "internet-gateway" {
  route_table_id         = "${aws_route_table.route-table.id}"
  gateway_id             = "${aws_internet_gateway.internet-gatway.id}"
  destination_cidr_block = "0.0.0.0/0"
}

# Security groups
resource "aws_security_group" "security-group" {
  name        = "${var.project-name}"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    project = "${var.project-name}"
  }
}


# ECS
resource "aws_ecr_repository" "repository" {
  name = "${var.project-name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project-name}"
}

data "template_file" "task-definition-template" {
  template = "${file("task-definitions/staging.json")}"

  vars {
    image = "${aws_ecr_repository.repository.repository_url}/${var.project-name}:latest"
  }
}

resource "aws_ecs_task_definition" "task-definition" {
  container_definitions = "${data.template_file.task-definition-template.rendered}"
  family = "staging"
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = "ecsTaskExecutionRole"
  task_role_arn = "ecsTaskExecutionRole"
  requires_compatibilities = [
    "FARGATE"
  ]
}

resource "aws_ecs_service" "service" {
  name            = "staging"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.task-definition.arn}"
  desired_count   = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      "${aws_subnet.subnet.id}"
    ]
    assign_public_ip = true
    security_groups = []
  }
}

