terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-2"
  profile = "default"
}

resource "aws_s3_bucket" "this" {
  bucket = "innodatatf"
  force_destroy = true
}

resource "aws_athena_database" "this" {
  name   = "innodate_db"
  bucket = aws_s3_bucket.this.bucket
}

resource "aws_glue_catalog_database" "this" {
  name = "innodata_catalog_db"

}

resource "aws_glue_crawler" "this" {
  database_name = aws_glue_catalog_database.this.name
  name          = "innodata_crawler"
  role          = aws_iam_role.this.arn

  s3_target {
    path = aws_s3_bucket.this.arn
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = "{\"Version\":1.0,\"CrawlerOutput\":{\"Partitions\":{\"AddOrUpdateBehavior\":\"InheritFromTable\"},\"Tables\":{\"AddOrUpdateBehavior\":\"MergeNewColumns\"}}}"
}

resource "aws_iam_role_policy" "this" {
  name = "crawler_policy"
  role = aws_iam_role.this.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "this" {
  name = "crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
}

