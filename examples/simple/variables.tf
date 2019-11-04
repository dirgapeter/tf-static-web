variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "The name of the project"
  type        = string
  default     = "simple"
}

variable "environment" {
  description = "The name of the environment"
  type        = string
  default     = "example"
}
