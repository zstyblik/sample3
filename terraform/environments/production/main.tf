locals {
  default_tags             = merge(var.default_tags, { "environment" : var.environment })
  deployment_package_fname = var.deployment_package_fname != null ? var.deployment_package_fname : "${path.module}/../../../deployment-package.zip"
  prefix                   = var.prefix_lookup[var.environment]
}

module "weather_iam" {
  source                 = "../../modules/weather-iam"
  prefix                 = local.prefix
  weather_s3_bucket_name = var.weather_s3_bucket_name
  weather_sm_secret_name = var.weather_sm_secret_name
  tags                   = local.default_tags
}

module "weather_storage" {
  source                             = "../../modules/weather-storage"
  weather_app_lambda_svc_role_arn    = module.weather_iam.lambda_service_role.arn
  weather_cloudfront_distribution_id = module.weather_cdn.cloudfront_distribution.id
  weather_s3_bucket_name             = var.weather_s3_bucket_name
  weather_s3_bucket_force_destroy    = var.weather_s3_bucket_force_destroy
  tags                               = local.default_tags
}

module "weather_cdn" {
  source                                 = "../../modules/weather-cdn"
  weather_s3_bucket_name                 = var.weather_s3_bucket_name
  weather_s3_bucket_regional_domain_name = module.weather_storage.s3_bucket.bucket_regional_domain_name
  tags                                   = local.default_tags
}

module "weather_app" {
  source                 = "../../modules/weather-app"
  lambda_zip             = local.deployment_package_fname
  lambda_function_name   = var.weather_lambda_function_name
  lambda_role_arn        = module.weather_iam.lambda_service_role.arn
  prefix                 = local.prefix
  weather_s3_bucket_name = var.weather_s3_bucket_name
  weather_sm_secret_name = var.weather_sm_secret_name
  tags                   = local.default_tags
}
