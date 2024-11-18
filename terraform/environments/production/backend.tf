terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "p-example-terraform-remote-state-123456"
    dynamodb_table = "p-example-terraform-state-lock-dynamo"
    region         = "eu-central-1"
    key            = "p-example-weather-terraform/production/main/terraform.tfstate"
  }
}
