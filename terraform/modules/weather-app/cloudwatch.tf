resource "aws_cloudwatch_log_group" "weather_app" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.logging_retention_days

  tags = merge(
    tomap({
      "Name"        = var.lambda_function_name,
      "custom:Tier" = "cloudwatch",
    }),
    var.tags
  )
}

resource "aws_cloudwatch_event_rule" "weather_app_data_update" {
  name                = var.lambda_function_name
  description         = "Trigger Weather Lambda to update data."
  schedule_expression = "rate(${var.weather_update_rate_minutes} minutes)"
  state               = var.weather_update_rate_minutes < 1 ? "DISABLED" : "ENABLED"

  tags = merge(
    tomap({
      "Name"        = var.lambda_function_name,
      "custom:Tier" = "cloudwatch",
    }),
    var.tags
  )
}

resource "aws_cloudwatch_event_target" "weather_app" {
  arn  = aws_lambda_function.weather_app.arn
  rule = aws_cloudwatch_event_rule.weather_app_data_update.id
}
