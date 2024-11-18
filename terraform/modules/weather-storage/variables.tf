variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of additional tags to be added."
}

variable "weather_app_lambda_svc_role_arn" {
  type        = string
  description = "ARN of IAM service role used by WeatherApp Lambda function."
}

variable "weather_cloudfront_distribution_id" {
  type        = string
  default     = "cloudfront-id-not-provided-not-exist"
  description = "ID of CloudFront Distribution which is going to serve WeatherApp content."
}

variable "weather_s3_bucket_name" {
  type        = string
  description = "Name of S3 bucket used as storage for weather app."
}

variable "weather_s3_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Force destuction of S3 bucket which contains weather data."
}
