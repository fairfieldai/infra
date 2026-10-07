resource "aws_s3_bucket" "site" {
  bucket           = "${var.bucket_name_prefix}-${local.bucket_name_suffix}"
  bucket_namespace = "account-regional"

  tags = merge(var.tags, {
    Name = "${var.bucket_name_prefix}-${local.bucket_name_suffix}"
  })
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Each deploy overwrites or deletes objects, leaving noncurrent versions that
# are only needed for a quick rollback.
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    expiration {
      expired_object_delete_marker = true
    }
  }

  depends_on = [aws_s3_bucket_versioning.site]
}

# s3:ListBucket makes S3 return 404 rather than 403 for missing keys, so
# CloudFront can serve the custom 404 page.
data "aws_iam_policy_document" "site" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }

  statement {
    sid       = "AllowCloudFrontList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Redirect-all website buckets answer every request with a 301 and never read
# objects, so the bucket stays fully private.
resource "aws_s3_bucket" "redirect" {
  count = local.create_redirect ? 1 : 0

  bucket           = "${var.bucket_name_prefix}-redirect-${local.bucket_name_suffix}"
  bucket_namespace = "account-regional"

  tags = merge(var.tags, {
    Name = "${var.bucket_name_prefix}-redirect-${local.bucket_name_suffix}"
  })
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  count = local.create_redirect ? 1 : 0

  bucket = aws_s3_bucket.redirect[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "redirect" {
  count = local.create_redirect ? 1 : 0

  bucket = aws_s3_bucket.redirect[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "redirect" {
  count = local.create_redirect ? 1 : 0

  bucket = aws_s3_bucket.redirect[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  count = local.create_redirect ? 1 : 0

  bucket = aws_s3_bucket.redirect[0].id

  redirect_all_requests_to {
    host_name = var.domain_name
    protocol  = "https"
  }
}

# Placeholder content so the site serves a page before the first deploy. The
# deploy overwrites these keys, and ignore_changes keeps Terraform from
# reverting them.
resource "aws_s3_object" "placeholder" {
  for_each = toset(["index.html", "404.html"])

  bucket        = aws_s3_bucket.site.id
  key           = each.value
  source        = "${path.module}/placeholder/index.html"
  content_type  = "text/html; charset=utf-8"
  cache_control = "public, max-age=300"

  tags = merge(var.tags, {
    Name = each.value
  })

  lifecycle {
    ignore_changes = all
  }
}
