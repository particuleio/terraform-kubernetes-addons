locals {
  tags          = var.tags
  arn-partition = var.arn-partition != "" ? var.arn-partition : data.aws_partition.current.partition
}
