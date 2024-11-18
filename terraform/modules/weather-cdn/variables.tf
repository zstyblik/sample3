variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of additional tags to be added."
}

variable "weather_s3_bucket_name" {
  type        = string
  description = "Name of S3 bucket where weather data and HTML are stored."
}

variable "weather_s3_bucket_regional_domain_name" {
  type        = string
  description = "Regional Domain name of S3 bucket."
}
