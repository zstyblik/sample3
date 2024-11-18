# NOTE(zstyblik): no CDN in DEV, of course.
# output "cloudfront_domain_name" {
#   value = module.weather_cdn.cloudfront_distribution.domain_name
# }

output "weather_s3_bucket_name" {
  value = module.weather_storage.s3_bucket.bucket
}

output "weather_lambda_function_name" {
  value = module.weather_app.lambda.function_name
}
