output "lambda_service_role" {
  value       = aws_iam_role.weather_lambda_svc_role
  description = "IAM service role for Lambda Function."
}
