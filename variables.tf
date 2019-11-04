variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
  default     = "static-web"
}

variable "project" {
  description = "Name of the project. Also used as a prefix in names of related resources."
  type        = string
}

variable "environment" {
  description = "Environment of the project. Also used as a prefix in names of related resources."
  type        = string
}

variable "manage_log_bucket" {
  description = "Defines whether this module should generate and manage its own s3 bucket for logging"
  type        = bool
  default     = true
}

variable "logging_prefix" {
  description = "A prefix in names for logging bucket"
  type        = string
  default     = "logs/"
}

variable "deployer_groups" {
  description = "The IAM groups that will get the policy assigned to deploy to the s3 bucket"
  type        = list(string)
  default     = []
}

variable "deployer_users" {
  description = "The IAM users that will get the policy assigned to deploy to the s3 bucket"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Optional Tags"
  type        = map(string)
  default     = {}
}
