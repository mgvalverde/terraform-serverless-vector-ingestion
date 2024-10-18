# TODO: module to handle IAM role creation

# Role
resource "aws_iam_role" "lambda_function" {
  #  name               = "sf-transaction-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = ["lambda.amazonaws.com"]
        },
        Action = ["sts:AssumeRole"]
      },
    ]
  })
}

# Policies
resource "aws_iam_policy" "ssm_read" {
  path        = "/"
  description = "Policy to allow read access to SSM parameters in the /${var.project}/* path"
  name_prefix = "lambda-vector-ingest-"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.project}/*"
      }
    ]
  })
}

# Attach
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}
resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.lambda_function.name
  policy_arn = aws_iam_policy.ssm_read.arn
}


