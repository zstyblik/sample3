variable "lambda_env_variables" {
  type        = map(any)
  default     = {}
  description = "Additional environment variables passed to lambda function."
}

variable "lambda_function_name" {
  type        = string
  description = "Name given to AWS Lambda Function resource."
}

variable "lambda_handler" {
  type        = string
  default     = "weather.lambda_handler"
  description = "Name of lambda handler."
}

variable "lambda_memory_size" {
  type        = number
  default     = 144
  description = "Lambda memory size in MB."
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN of IAM role to be used by Lambda."
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.11"
  description = "Lambda runtime."
}

variable "lambda_timeout_seconds" {
  type        = number
  default     = 15
  description = "Lambda timeout in seconds."
}
# "${path.module}/../${var.deployment_package_fname}"
# NOTE: this path is no longer true, resp. it's deeper.
variable "lambda_zip" {
  type        = string
  description = "Path to ZIP file."
}

variable "logging_retention_days" {
  type        = number
  default     = 1
  description = "CloudWatch log retention in days."
}

variable "prefix" {
  type        = string
  description = "Prepend prefix to created resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of additional tags to be added."
}

variable "weather_s3_bucket_name" {
  type        = string
  description = "Name of S3 bucket where weather data and HTML will be stored."
}

variable "weather_sm_secret_name" {
  type        = string
  description = "Name of Secrets Manager secret which contains weather API key."
}

variable "weather_update_rate_minutes" {
  type        = number
  default     = 60
  description = "How often weather data should be updated in minutes. Value of less than 1 will disable updates."
}
