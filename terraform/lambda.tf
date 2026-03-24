# ── Package Lambda functions as zip files ──
data "archive_file" "bts_downloader" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/bts_downloader"
  output_path = "${path.module}/../lambda/bts_downloader/bts_downloader.zip"
}

data "archive_file" "noaa_fetcher" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/noaa_fetcher"
  output_path = "${path.module}/../lambda/noaa_fetcher/noaa_fetcher.zip"
}

# ── BTS Downloader Lambda ──
resource "aws_lambda_function" "bts_downloader" {
  filename         = data.archive_file.bts_downloader.output_path
  function_name    = "${var.project_name}-bts-downloader"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 300
  memory_size      = 512
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