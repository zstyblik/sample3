locals {
  # NOTE(zstyblik): If not provided, assume it's the same region.
  sm_region = var.weather_sm_region != null ? var.weather_sm_region : local.aws_region
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "weather_lambda_svc_role" {
  name = "${var.prefix}WeatherServiceRoleForLambda"
  path = "/service-role/"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    tomap({
      "Name" : "${var.prefix}WeatherServiceRoleForLambda",
      "custom:Tier" = "iam",
    }),
    var.tags
  )
}

data "aws_iam_policy_document" "weather_lambda_logging" {
  statement {
    sid = "Logging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs::${local.aws_account_id}:*"
    ]
  }
}

resource "aws_iam_policy" "weather_lambda_logging" {
  name        = "${var.prefix}WeatherLambdaLoggingPolicy"
  path        = "/"
  description = "Policy allows logging from Lambda function."
  policy      = data.aws_iam_policy_document.weather_lambda_logging.json

  tags = merge(
    tomap({
      "Name" : "${var.prefix}WeatherLambdaLoggingPolicy",
      "custom:Tier" = "iam",
    }),
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "weather_lambda_logs" {
  role       = aws_iam_role.weather_lambda_svc_role.name
  policy_arn = aws_iam_policy.weather_lambda_logging.arn
}

data "aws_iam_policy_document" "weather_lambda_s3" {
  statement {
    sid = "UploadData"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.weather_s3_bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "weather_lambda_s3" {
  name        = "${var.prefix}WeatherLambdaS3Policy"
  path        = "/"
  description = "Policy allows S3 access from Lambda function."
  policy      = data.aws_iam_policy_document.weather_lambda_s3.json

  tags = merge(
    tomap({
      "Name" : "${var.prefix}WeatherLambdaS3Policy",
      "custom:Tier" = "iam",
    }),
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "weather_lambda_s3" {
  role       = aws_iam_role.weather_lambda_svc_role.name
  policy_arn = aws_iam_policy.weather_lambda_s3.arn
}

data "aws_iam_policy_document" "weather_sm_secrets" {
  statement {
    sid = "GetSMSecret"

    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:${local.sm_region}:${local.aws_account_id}:secret:${var.weather_sm_secret_name}-*"
    ]
  }
}

resource "aws_iam_policy" "weather_lambda_sm_secrets" {
  name        = "${var.prefix}WeatherLambdaSMPolicy"
  description = "Policy allows to read secrets from Secrets Manager."
  path        = "/"
  policy      = data.aws_iam_policy_document.weather_sm_secrets.json

  tags = merge(
    tomap({
      "Name" : "${var.prefix}WeatherLambdaSMPolicy",
      "custom:Tier" = "iam",
    }),
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "weather_sm_secrets" {
  role       = aws_iam_role.weather_lambda_svc_role.name
  policy_arn = aws_iam_policy.weather_lambda_sm_secrets.arn
}
