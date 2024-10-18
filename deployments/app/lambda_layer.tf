# Create a lambda layer having as target a python requirements.txt


module "layer_qdrant" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  create_layer = true

  # Layer configuration
  layer_name  = "lambda-layer-qdrant"
  description = "Lambda layer with dependencies for Qdrant and Llama-index"
  compatible_runtimes = ["python3.12"]

  # Build configuration
  build_in_docker = true
  source_path   = [
    {
      path="${path.module}/assets/layers/qdrant"
      pip_requirements = true
      prefix_in_zip    = "python" # required to get the path correct
    }
  ]
  artifacts_dir = "${path.module}/.builds/layers/"

  # Store artifact in s3
  store_on_s3 = true
  s3_bucket   = aws_s3_bucket.artifacts.id
  s3_prefix   = "lambda-builds/layers/qdrant/"
}

module "layer_weaviate" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  create_layer = true

  # Layer configuration
  layer_name  = "lambda-layer-weaviate"
  description = "Lambda layer with dependencies for Weaviate and Llama-index"
  compatible_runtimes = ["python3.12"]

  # Build configuration
  build_in_docker = true
  source_path   = [
    {
      path="${path.module}/assets/layers/weaviate"
      pip_requirements = true
      prefix_in_zip    = "python" # required to get the path correct
    }
  ]
  artifacts_dir = "${path.module}/.builds/layers/"

  # Store artifact in s3
  store_on_s3 = true
  s3_bucket   = aws_s3_bucket.artifacts.id
  s3_prefix   = "lambda-builds/layers/weaviate/"
}
