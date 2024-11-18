variable "default_tags" {
  type        = map(any)
  default     = {}
  description = "Default extra tags to be added to resources."
}
# FIXME: probably make mandatory, or idk
variable "deployment_package_fname" {
  type        = string
  default     = null
  description = "Path to lambda ZIP package."
}

variable "environment" {
  type        = string
  description = "Environment we're making changes to."

  validation {
    condition     = can(regex("^(production|staging|development)$", var.environment))
    error_message = "Environment must be one of 'production', 'staging' or 'development'."
  }
}

variable "weather_lambda_function_name" {
  type        = string
  description = "Name of Lambda function resource."
}

variable "weather_s3_bucket_name" {
  type        = string
  description = "Name of S3 bucket where weather data will be stored."
}

variable "weather_s3_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Force destuction of S3 bucket which contains weather data."
}

variable "weather_sm_secret_name" {
  type        = string
  description = "Name of Secrets Manager secret which holds API key."
}

variable "prefix_lookup" {
  type = map(string)
  default = {
    development = "Dev"
    staging     = "Stage"
    production  = "Prod"
  }
}
