variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "personal"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "flight-pipeline"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
  default     = "013849273657"
}