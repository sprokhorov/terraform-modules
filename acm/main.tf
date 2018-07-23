resource "aws_acm_certificate" "cert" {
  domain_name                   = "${var.domain}"
  subject_alternative_names     = ["${var.alternative_names}"]
  validation_method             = "DNS"

  tags {
    Name                        = "${var.domain}"
    Role                        = "certificate"
    Service                     = "acm"
    Resource                    = "acm_certificate"
    Region                      = "${var.aws_region}"
    Environment                 = "default"
    Type                        = "wildcard"
    Managed                     = "By Terraform"
  }
}

data "aws_route53_zone" "zone" {
  name                          = "${var.domain}."
  private_zone                  = false
}

locals {
  domain_validation_opts        = "${flatten(aws_acm_certificate.cert.domain_validation_options)}"
}

resource "aws_route53_record" "cert_validation" {
  count                         = "${length(var.alternative_names) + 1}"
  name                          = "${lookup(local.domain_validation_opts[count.index], "resource_record_name")}"
  type                          = "${lookup(local.domain_validation_opts[count.index], "resource_record_type")}"
  zone_id                       = "${data.aws_route53_zone.zone.id}"
  records                       = ["${lookup(local.domain_validation_opts[count.index], "resource_record_value")}"]
  ttl                           = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn               = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns       = ["${aws_route53_record.cert_validation.*.fqdn}"]
}

