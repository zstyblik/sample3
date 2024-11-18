resource "aws_lambda_function" "weather_app" {
  # Use S3 or some kind of "artifactory" to store previous versions without need
  # to rebuild everything from scratch which in case of Python could mean
  # completely different dependencies. Or maybe with `publish = true`.
  filename                       = var.lambda_zip
  function_name                  = var.lambda_function_name
  description                    = "Download data from OpenWeathermap API and upload it to S3"
  handler                        = var.lambda_handler
  memory_size                    = var.lambda_memory_size
  reserved_concurrent_executions = 2
  role                           = var.lambda_role_arn
  runtime                        = var.lambda_runtime

  environment {
    variables = merge(
      tomap({
        "WEATHER_S3_BUCKET" : var.weather_s3_bucket_name,
        "WEATHER_SM_SECRET_NAME" : var.weather_sm_secret_name,
      }),
      var.lambda_env_variables
    )
  }
  source_code_hash = filebase64sha256(var.lambda_zip)
  timeout          = var.lambda_timeout_seconds

  tags = merge(
    tomap({
      "Name"        = var.lambda_function_name,
      "custom:Tier" = "lambda",
    }),
    var.tags
  )

  depends_on = [
    aws_cloudwatch_log_group.weather_app,
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_app.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weather_app_data_update.arn

  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.weather_app
    ]
  }
}
