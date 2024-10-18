## S3 Bucket
locals {
  # This policy will be attached to the main queue at creation time,
  # thus we don't provide "resource" statement
  s3_queue_policy_statements = {
    account = {
      sid = "S3WriteEventSQS"
      # Allow just send messages
      actions = [
        "sqs:SendMessage",
      ]
      principals = [
        {
          type = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]
      # Allow only your bucket to send messages
      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values = [aws_s3_bucket.this.arn]
        }
      ]
    }
  }
  ssm_prefix = format("/%s/%s/%s/", var.project, "sqs", "data")

}

module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.2.0"

  create          = true
  create_dlq      = true
  name            = "s3-data-events"
  use_name_prefix = true

  sqs_managed_sse_enabled = true

  create_queue_policy     = true
  queue_policy_statements = local.s3_queue_policy_statements

  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
}

