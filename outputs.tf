output "website_bucket" {
  value = aws_s3_bucket.website_bucket
}

output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.website_bucket
}
