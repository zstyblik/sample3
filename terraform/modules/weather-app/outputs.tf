output "lambda" {
  value       = aws_lambda_function.weather_app
  description = "WeatherApp lambda function."
}

output "lambda_log_group" {
  value       = aws_cloudwatch_log_group.weather_app
  description = "WeatherApp CloudWatch log group."
}
