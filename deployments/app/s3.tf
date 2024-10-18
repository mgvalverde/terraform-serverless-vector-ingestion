resource "aws_s3_bucket" "this" {
  bucket_prefix = var.s3_bucket_prefix
}

# Event configuration to deliver it to SQS
resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  dynamic "queue" {
    for_each = var.s3_event_queue
    content {
      id = queue.value.id
      queue_arn = try(queue.value.queue_arn, module.sqs.queue_arn)
      events = try(queue.value.events, ["s3:ObjectCreated:*"])
      filter_prefix = try(queue.value.filter_prefix, null)
      filter_suffix = try(queue.value.filter_suffix, null)
    }
  }

}

## To store the
resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = var.s3_bucket_artifacts_prefix
}