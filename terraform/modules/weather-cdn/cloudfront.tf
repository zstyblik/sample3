resource "aws_cloudfront_cache_policy" "custom_caching" {
  name = "CustomCaching"

  default_ttl = 60
  max_ttl     = 300
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "weather_cdn" {
  # NOTE(zstyblik): no idea about domain name
  name                              = "${var.weather_s3_bucket_name}.s3.eu-central-1.amazona"
  description                       = "Managed by Terraform"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "weather_cdn" {
  aliases         = []
  enabled         = true
  http_version    = "http2"
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"
  # NOTE: it takes up to 15 minutes to delete, therefore ...
  # Disables the distribution instead of deleting it when destroying the resource
  # through Terraform. If this is set, the distribution needs to be deleted
  # manually afterwards.
  retain_on_delete = false

  wait_for_deployment = true

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    cache_policy_id = aws_cloudfront_cache_policy.custom_caching.id
    cached_methods = [
      "GET",
      "HEAD",
    ]
    compress = true
    # AMZ Managed policy CORS-S3Origin
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
    smooth_streaming         = false
    target_origin_id         = "S3-${var.weather_s3_bucket_name}"
    trusted_signers          = []
    viewer_protocol_policy   = "redirect-to-https"
  }

  origin {
    domain_name              = var.weather_s3_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.weather_cdn.id
    origin_id                = "S3-${var.weather_s3_bucket_name}"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    tomap({
      "custom:Tier" = "cdn",
    }),
    var.tags
  )
}
