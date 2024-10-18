locals {
  # lambda_source_path = format("%s/assets/lambda", path.cwd)

  sqs_report_batch_item_failures = var.sqs_allow_report_batch_item_failures ? ["ReportBatchItemFailures"] : []
  lambda_environment_variables = merge(
    var.lambda_environment_variables,
    {
      SQS_ACK_QUEUE_URL = module.sqs.queue_url
    }
  )
}

## ZIP
# module "lambda_vector" {
#   source  = "terraform-aws-modules/lambda/aws"
#   version = "7.13.0"
#
#   create_function = true
#   publish = true
#   # package_type  = "Zip"
#   # Lambda configuration
#   runtime       = "python3.12"
#   function_name = "lambda-pdf-proccess"
#   description   = "Lambda function to receive message from SQS and process and ingest into a vector db documents from S3"
#   handler       = "main.handler"
#   layers = [
#     module.layer_qdrant.lambda_layer_arn,
#   ]
#   timeout = var.lambda_timeout
#   memory_size = var.lambda_memory_size
#
#   ## Envvar configuration
#   environment_variables = var.lambda_environment_variables
#
#   # Permissions
#   lambda_role = aws_iam_role.lambda_function.arn
#   create_role = false
#
#   # Build configuration
#   source_path = [
#     {
#       path = "${path.cwd}/assets/lambda/weaviate-ingestion/"
#       # pip_requirements = "${path.cwd}/assets/vector-ingestion/requirements.txt"
#       # pip_tmp_dir      = "${path.root}/assets"
#     }
#   ]
#
#   # Store artifact in s3
#   artifacts_dir = "${path.root}/.builds/lambda/"
#   s3_bucket     = aws_s3_bucket.artifacts.id
#   s3_prefix = "lambda-builds/vector-ingestion/"
#
#   # Triggers
#   event_source_mapping = [
#     {
#       event_source_arn        = module.sqs.queue_arn
#       enabled                 = true
#       batch_size = var.sqs_batch_size
#       # Allow ReportBatchItemFailures
#       function_response_types = local.sqs_report_batch_item_failures
#       scaling_config = [
#         {
#           maximum_concurrency = var.sqs_maximum_concurrency
#         }
#       ]
#     }
#   ]
#
# }

## DOCKER

data "aws_ssm_parameter" "uri" {
  name = var.lambda_image_uri_ssm
}

module "lambda_vector" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  create_function = true
  publish = true

  # Lambda configuration
  package_type  = "Image"
  image_uri      = data.aws_ssm_parameter.uri.value
  architectures = ["x86_64"]
  create_package = false

  runtime       = "python3.12"
  function_name = "lambda-data-proccessing"
  description   = "Lambda function to receive message from SQS and process and ingest into a Qdrant vector db documents from S3"
  handler       = "main.handler"

  timeout = var.lambda_timeout
  memory_size = var.lambda_memory_size


  ## Envvar configuration
  environment_variables = local.lambda_environment_variables

  # Permissions
  lambda_role = aws_iam_role.lambda_function.arn
  create_role = false


  # Triggers
  event_source_mapping = [
    {
      event_source_arn        = module.sqs.queue_arn
      enabled                 = true
      batch_size = var.sqs_batch_size
      # Allow ReportBatchItemFailures
      function_response_types = local.sqs_report_batch_item_failures
      scaling_config = [
        {
          maximum_concurrency = var.sqs_maximum_concurrency
        }
      ]
    }
  ]

}
