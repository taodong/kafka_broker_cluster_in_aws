terragrunt = {
  # Configure Terragrunt to automatically store tfstate files in an S3 bucket
  remote_state = {
    backend = "s3"
    config {
      encrypt = true
      bucket = "${s3-bucket-put-terraform-state}"
      key = "kafka/terraform.tfstate"
      region = "${region}"
      dynamodb_table = "terraform_locks"
    }
  }

  terraform = {
    extra_arguments "custom_vars" {
      arguments = [
        "-var-file=variables.tfvars.json",
      ]
    }
  }
}