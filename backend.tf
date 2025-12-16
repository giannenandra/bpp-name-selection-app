terraform {
  backend "s3" {
    bucket         = "terraform-state-988c3253" 
    key            = "name-selection-app/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}