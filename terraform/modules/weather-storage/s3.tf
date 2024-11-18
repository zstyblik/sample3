resource "aws_s3_bucket" "weather_data" {
  bucket = var.weather_s3_bucket_name
  # NOTE(zstyblik): needed in order to destroy non-empty bucket.
  force_destroy = var.weather_s3_bucket_force_destroy

  # FIXME(zstyblik): cannot use vars in lifecycle, must duplicate resource +
  # count -> more work.
  # Everything would have to be duplicated, but it looks like ternary can be
  # used in output.
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = merge(
    tomap({
      "Name"        = var.weather_s3_bucket_name,
      "custom:Tier" = "s3",
    }),
    var.tags
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "weather_data" {
  bucket = aws_s3_bucket.weather_data.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "weather_data" {
  bucket = aws_s3_bucket.weather_data.bucket

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 60
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "weather_data" {
  bucket = aws_s3_bucket.weather_data.id

  rule {
    id = "rule-1"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    transition {
      days          = 3
      storage_class = "INTELLIGENT_TIERING"
    }

    status = "Enabled"
  }

  rule {
    id = "rule-2"

    noncurrent_version_expiration {
      newer_noncurrent_versions = 3
      noncurrent_days           = 7
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_request_payment_configuration" "weather_data" {
  bucket = aws_s3_bucket.weather_data.bucket
  payer  = "BucketOwner"
}

resource "aws_s3_bucket_public_access_block" "weather_data" {
  bucket                  = aws_s3_bucket.weather_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "weather_data" {
  bucket = aws_s3_bucket.weather_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "weather_data" {
  bucket = aws_s3_bucket.weather_data.id
  policy = jsonencode(
    {
      Statement = [
        {
          Sid    = "WeatherLambdaUploads"
          Effect = "Allow"
          Principal = {
            AWS = [
              var.weather_app_lambda_svc_role_arn
            ]
          }
          Action   = "s3:PutObject"
          Resource = "arn:aws:s3:::${var.weather_s3_bucket_name}/*"
        },
        {
          "Sid" : "AllowCloudFrontServicePrincipal",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "cloudfront.amazonaws.com"
          },
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.weather_data.bucket}/index.html",
          "Condition" : {
            "StringEquals" : {
              "AWS:SourceArn" : "arn:aws:cloudfront::${local.aws_account_id}:distribution/${var.weather_cloudfront_distribution_id}"
            }
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}
