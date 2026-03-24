output "raw_bucket_name" {
  description = "S3 raw bucket name"
  value       = aws_s3_bucket.raw.bucket
}

output "curated_bucket_name" {
  description = "S3 curated bucket name"
  value       = aws_s3_bucket.curated.bucket
}

output "static_bucket_name" {
  description = "S3 static bucket name"
  value       = aws_s3_bucket.static.bucket
}

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.main.name
}