# GLOBAL

variable "owner" {
  type        = string
  description = "Project's owner name "
}

variable "project" {
  type        = string
  description = "Project's name"
}

variable "environment" {
  type        = string
  default     = "sandbox"
  description = "Environemnt's name"
}

variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "The AWS region where resources will be created"
}

variable "tags" {
  type = map(string)
  default = {}
}

# S3

variable "s3_bucket_prefix" {
  type        = string
  description = "S3 bucket preffix"
}

variable "s3_bucket_artifacts_prefix" {
  type        = string
  description = "S3 bucket preffix to store artifacts"
}

# LAMBDA
variable "lambda_timeout" {
  default = 150
}

variable "lambda_memory_size" {
  default = 512
}
variable "lambda_image_uri_ssm" {
  type = string
  description = "SSM Parameter name containing the image URI for the container creation"
}

variable "lambda_environment_variables" {
  type = map(string)
  default = {}
  description = "Set of external environment variable to use in the main vector ingestion lambda"
}

# SQS
variable "sqs_visibility_timeout_seconds" {
  default     = 300
  type        = number
  description = "Time that a message is not visible after it is delivered. It must be larger or equal than lambda timeout. Recommended x6"
}

variable "sqs_create_dlq" {
  default     = true
  description = "Create a DLQ for the SQS main queue"
}

variable "sqs_max_receive_count" {
  default     = 5
  description = "Max receive count for the DLQ"
}

variable "sqs_redrive_permission" {
  default     = "byQueue"
  description = "Permission for the redrive policy"
}

variable "s3_notification_prefix" {
  type        = string
  description = "Prefix for the S3 notification"
  default     = ""
}

variable "s3_notification_suffix" {
  type        = string
  description = "Suffix for the S3 notification"
  default     = ""
}
variable "s3_event_queue" {
  type = list(any)
  description = ""
  default = []
}

variable "sqs_batch_size" {
  type        = number
  default     = 1
  description = "Batch size for lambda from SQS to process"
}

variable "sqs_allow_report_batch_item_failures" {
  type        = bool
  default     = true
  description = "Batch size for lambda from SQS to process"
}

variable "sqs_maximum_concurrency" {
  type        = number
  default     = 10
  description = "Maximum concurrency for lambda from SQS to process"
}


