terraform = {
  backend "s3" {
    bucket = "tao-terraform-state-bucket"
    key = "kafka/us-west-1/tao/terraform.tfstate"
    region = "us-west-1"
    dynamodb_table = "terraform_locks-test4"
    encrypt = true
  }
}