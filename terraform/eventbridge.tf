# ── BTS trigger — 1st of every month at 6am UTC ──
resource "aws_cloudwatch_event_rule" "bts_monthly" {
  name                = "${var.project_name}-bts-monthly"
  description         = "Trigger BTS downloader on 1st of every month"
  schedule_expression = "cron(0 6 1 * ? *)"

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "bts_lambda" {
  rule      = aws_cloudwatch_event_rule.bts_monthly.name
  target_id = "bts-downloader"
  arn       = aws_lambda_function.bts_downloader.arn
}

resource "aws_lambda_permission" "bts_eventbridge" {
  statement_id  = "AllowEventBridgeBTS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bts_downloader.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bts_monthly.arn
}

# ── NOAA trigger — every day at 2am UTC ──
resource "aws_cloudwatch_event_rule" "noaa_daily" {
  name                = "${var.project_name}-noaa-daily"
  description         = "Trigger NOAA fetcher every day"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "noaa_lambda" {
  rule      = aws_cloudwatch_event_rule.noaa_daily.name
  target_id = "noaa-fetcher"
  arn       = aws_lambda_function.noaa_fetcher.arn
}

resource "aws_lambda_permission" "noaa_eventbridge" {
  statement_id  = "AllowEventBridgeNOAA"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.noaa_fetcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.noaa_daily.arn
}