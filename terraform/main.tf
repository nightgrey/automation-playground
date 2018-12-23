variable "project-name" {
  type = "string"
  default = "automation-playground"
}

provider "aws" {
  region = "eu-central-1"
  shared_credentials_file = "$HOME/.aws/credentials"
}

resource "aws_ecr_repository" "repository" {
  name = "${var.project-name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "automation-playground"
}

# Task definition
data "template_file" "task-definition-template" {
  template = "${file("task-definitions/staging.tpl")}"

  vars {
    image = "${aws_ecr_repository.repository.repository_url}/${var.project-name}:latest"
  }
}

resource "aws_ecs_task_definition" "task-definition" {
  container_definitions = "${data.template_file.task-definition-template.rendered}"
  family = "staging"
}

resource "aws_ecs_service" "service" {
  name = "staging"
  task_definition = "staging"
  launch_type = "fargate"
}



