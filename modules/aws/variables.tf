# AWS Module Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}