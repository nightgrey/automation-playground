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
  name = "automation-playground-development"
}