terraform {
  # NOTE(zstyblik): this is just for demo. IRL these would be different.
  backend "s3" {
    encrypt        = true
    bucket         = "p-example-terraform-remote-state-123456"
    dynamodb_table = "p-example-terraform-state-lock-dynamo"
    region         = "eu-central-1"
    # NOTE(zstyblik): key is set up by CI/CD.
  }
}
