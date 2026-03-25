# ── Install dependencies and package BTS Lambda ──
resource "null_resource" "bts_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/../lambda/bts_downloader/requirements.txt")
    handler      = filemd5("${path.module}/../lambda/bts_downloader/handler.py")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/../lambda/bts_downloader/requirements.txt -t ${path.module}/../lambda/bts_downloader/ --quiet"
  }
}

data "archive_file" "bts_downloader" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/bts_downloader"
  output_path = "${path.module}/../lambda/bts_downloader/bts_downloader.zip"
  excludes    = ["bts_downloader.zip"]

  depends_on = [null_resource.bts_dependencies]
}

# ── Install dependencies and package NOAA Lambda ──
resource "null_resource" "noaa_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/../lambda/noaa_fetcher/requirements.txt")
    handler      = filemd5("${path.module}/../lambda/noaa_fetcher/handler.py")
  }

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/../lambda/noaa_fetcher/requirements.txt -t ${path.module}/../lambda/noaa_fetcher/ --quiet"
  }
}

data "archive_file" "noaa_fetcher" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/noaa_fetcher"
  output_path = "${path.module}/../lambda/noaa_fetcher/noaa_fetcher.zip"
  excludes    = ["noaa_fetcher.zip"]

  depends_on = [null_resource.noaa_dependencies]
}

# ── BTS Downloader Lambda ──
resource "aws_lambda_function" "bts_downloader" {
  filename         = data.archive_file.bts_downloader.output_path
  function_name    = "${var.project_name}-bts-downloader"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 1024
  source_code_hash = data.archive_file.bts_downloader.output_base64sha256

  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
    }
  }

  tags = {
    Project = var.project_name
  }
}

# ── NOAA Fetcher Lambda ──
resource "aws_lambda_function" "noaa_fetcher" {
  filename         = data.archive_file.noaa_fetcher.output_path
  function_name    = "${var.project_name}-noaa-fetcher"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 256
  source_code_hash = data.archive_file.noaa_fetcher.output_base64sha256

  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
    }
  }

  tags = {
    Project = var.project_name
  }
}