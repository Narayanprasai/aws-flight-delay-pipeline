# ── Raw bucket (landing zone for BTS and NOAA data) ──
resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw-${var.account_id}"

  tags = {
    Project     = var.project_name
    Environment = "prod"
    Layer       = "raw"
  }
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── Curated bucket (cleaned and joined data from dbt) ──
resource "aws_s3_bucket" "curated" {
  bucket = "${var.project_name}-curated-${var.account_id}"

  tags = {
    Project     = var.project_name
    Environment = "prod"
    Layer       = "curated"
  }
}

resource "aws_s3_bucket_versioning" "curated" {
  bucket = aws_s3_bucket.curated.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "curated" {
  bucket                  = aws_s3_bucket.curated.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── Static bucket (airport reference CSV) ──
resource "aws_s3_bucket" "static" {
  bucket = "${var.project_name}-static-${var.account_id}"

  tags = {
    Project     = var.project_name
    Environment = "prod"
    Layer       = "static"
  }
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── Athena results bucket (Athena needs somewhere to write query results) ──
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-results-${var.account_id}"

  tags = {
    Project     = var.project_name
    Environment = "prod"
    Layer       = "athena"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}