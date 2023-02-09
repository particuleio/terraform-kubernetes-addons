module "s3_logging_bucket" {

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true

  bucket = "${var.cluster-name}-eks-addons-s3-logging"
  acl    = "private"

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}
