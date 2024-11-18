environment = "development"
default_tags = {
  "custom:Project"    = "weather"
  "custom:CostCenter" = "example"
}
# NOTE(zstyblik): CI_MERGE_REQUEST_ID will be appended to this variable.
weather_lambda_function_name = "d-example-weather-lambda"
# NOTE(zstyblik): CI_MERGE_REQUEST_ID will be appended to this variable.
weather_s3_bucket_name          = "d-example-weather-123456"
weather_s3_bucket_force_destroy = true
# NOTE(zstyblik): I'm not creating new secret for this demo. This should point
# to something else than PROD IRL.
weather_sm_secret_name = "prod/ExampleWeather/secrets"
