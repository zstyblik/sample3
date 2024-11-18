variable "prefix" {
  type        = string
  description = "Prefix created resources."
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

variable "weather_sm_region" {
  type        = string
  default     = null
  description = "AWS region where Secrets Manager secret is located."
}
