# ====================
# IAM Role + Policies
# ====================
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_policy" "lambda_basic_policy" {
  name   = "lambda_basic_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_basic_policy.arn
}

# ====================
# SQS + DLQ
# ====================
resource "aws_sqs_queue" "dlq" {
  name = "my-dlq"
}

resource "aws_sqs_queue" "main_queue" {
  name = "my-main-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
  depends_on = [aws_sqs_queue.dlq]

}

# ====================
# Lambdas
# ====================
resource "aws_lambda_function" "lambda_from_sqs" {
  function_name = "lambda_from_sqs"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  filename = "${path.module}/lambda_from_sqs.zip"
}

resource "aws_lambda_function" "lambda_direct" {
  function_name = "lambda_direct"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  filename = "${path.module}/lambda_direct.zip"
}

# Permissão para Lambda ser chamada pelo SQS
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.lambda_from_sqs.arn
}

# ====================
# API Gateway
# ====================
resource "aws_api_gateway_rest_api" "api_cloud" {
  name        = "api-cloud"
  description = "API Cloud LocalStack"
}

# Root Resource
resource "aws_api_gateway_resource" "resource_async" {
  rest_api_id = aws_api_gateway_rest_api.api_cloud.id
  parent_id   = aws_api_gateway_rest_api.api_cloud.root_resource_id
  path_part   = "async"
}

resource "aws_api_gateway_resource" "resource_sync" {
  rest_api_id = aws_api_gateway_rest_api.api_cloud.id
  parent_id   = aws_api_gateway_rest_api.api_cloud.root_resource_id
  path_part   = "sync"
}

# Async Method (POST -> SQS)
resource "aws_api_gateway_method" "async_post" {
  rest_api_id   = aws_api_gateway_rest_api.api_cloud.id
  resource_id   = aws_api_gateway_resource.resource_async.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "async_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_cloud.id
  resource_id             = aws_api_gateway_resource.resource_async.id
  http_method             = aws_api_gateway_method.async_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_sqs_queue.main_queue.arn
}

# Sync Method (GET -> Lambda Direct)
resource "aws_api_gateway_method" "sync_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_cloud.id
  resource_id   = aws_api_gateway_resource.resource_sync.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sync_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_cloud.id
  resource_id             = aws_api_gateway_resource.resource_sync.id
  http_method             = aws_api_gateway_method.sync_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_direct.invoke_arn
}

# Deploy API
resource "aws_api_gateway_deployment" "api_deploy" {
  depends_on = [
    aws_api_gateway_integration.async_integration,
    aws_api_gateway_integration.sync_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api_cloud.id
  #stage_name  = "dev"
}
