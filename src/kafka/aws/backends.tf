terraform = {
  backend "s3" {
    bucket = "veevacrm-mc-dt-temp"
    key = "mc-dt/us-west-1/tao/terraform.tfstate"
    region = "us-west-1"
    dynamodb_table = "terraform_locks-test4"
    encrypt = true
  }
}