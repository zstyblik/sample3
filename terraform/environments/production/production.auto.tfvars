environment = "production"
default_tags = {
  "custom:Project"    = "weather"
  "custom:CostCenter" = "example"
}
weather_lambda_function_name    = "p-example-weather-lambda"
weather_s3_bucket_name          = "p-example-weather-123456"
weather_s3_bucket_force_destroy = false
weather_sm_secret_name          = "prod/ExampleWeather/secrets"
