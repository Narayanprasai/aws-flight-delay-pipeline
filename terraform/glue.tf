resource "aws_glue_catalog_database" "main" {
  name        = "${var.project_name}_catalog"
  description = "Glue catalog for flight delay pipeline"
}

resource "aws_glue_crawler" "flights" {
  name          = "${var.project_name}-flights-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.main.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/flights/"
  }

  schedule = "cron(0 6 1 * ? *)"

  tags = {
    Project = var.project_name
  }
}

resource "aws_glue_crawler" "weather" {
  name          = "${var.project_name}-weather-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.main.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/weather/"
  }

  schedule = "cron(0 7 * * ? *)"

  tags = {
    Project = var.project_name
  }
}