resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name = var.domain_name
  })
}

# The apex never sends mail (the community inbox is inbox.<domain>, whose SPF
# and DMARC records the mailbox stack manages), so tell receivers to reject
# anything claiming to be from it.
resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = ["v=spf1 -all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = ["v=DMARC1; p=reject"]
}

# Verifies the domain for GitHub Pages in the fairfieldai organization, so no
# other account can claim fairfieldct.ai or its subdomains for a Pages site.
resource "aws_route53_record" "github_pages_challenge" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_github-pages-challenge-fairfieldai.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = ["d1b28610e479e7c6945649a36e5b91"]
}

# Verifies the domain for the fairfieldai organization, so GitHub can mark it
# verified and restrict notification email to fairfieldct.ai addresses.
resource "aws_route53_record" "github_org_challenge" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "_gh-fairfieldai-o.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = ["f550544959"]
}
