# MAIN
owner                      = "<REPLACE_OWNER>"
project                    = "vectorized"       # This parameter is important, it's used to provide access to SSM params, that's why SSM parameters starts with "vectorized"
environment                = "sandbox"
aws_region                 = "<REPLACE_REGION>"
# S3
s3_bucket_prefix           = "vectorized-data-"
s3_bucket_artifacts_prefix = "vectorized-artifacts-"
s3_event_queue = [
  {
    id : "NewDocEvent",
    events : ["s3:ObjectCreated:*"],
    filter_prefix : "landing/",       # Only documents in landing will trigger the event
  }
]
# SQS
sqs_visibility_timeout_seconds       = 150
sqs_max_receive_count                = 10
# EVENT SOURCE MAPPING
sqs_batch_size                       = 1
sqs_maximum_concurrency              = 3
sqs_allow_report_batch_item_failures = true
# LAMBDA
lambda_timeout     = 120
lambda_memory_size = 256
lambda_image_uri_ssm = "/vectorized/qdrant/ecr/image"          # Make sure it exists
lambda_environment_variables = {
  DENSE_EMBED_MODEL_NAME     = "jina-embeddings-v3"
  SPARSE_EMBED_MODEL_NAME    = "Qdrant/bm42-all-minilm-l6-v2-attentions"
  JINA_API_SSM               = "/vectorized/jina/apikey"       # Make sure it exists
  QDRANT_API_SSM             = "/vectorized/qdrant/apikey"     # Make sure it exists
  QDRANT_URL_SSM             = "/vectorized/qdrant/url"        # Make sure it exists
  NAMESPACE_UUID             = "/vectorized/qdrant/namespace"  # Make sure it exists
}

