#### Instances ###############################################################

module "instance" {
  source          = "git::ssh://git@source.sanoma.com:7999/tfmod/ec2.git?ref=feature/multiaccount"
  name            = "${var.instance_name}"
  count           = "${var.instance_count}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${compact(concat(var.security_groups, list(module.loadbalancer.security_group_id), list(module.db.security_group_id)))}"]
  tags            = "${var.tags}"
}

#### Application Load Balancer ################################################

module "sg_lb" {
  source      = "git::ssh://git@source.sanoma.com:7999/tfmod/sg.git?ref=0.0.4"
  name        = "lb"
  tags        = "${var.tags}"
  ports       = "${var.sg_lb_ports}"
  cidr_blocks = ["${var.sg_lb_cidr}"]
}

module "loadbalancer" {
  source          = "git::ssh://git@source.sanoma.com:7999/tfmod/lb.git?ref=0.0.5"
  security_groups = ["${module.sg_lb.id}"]
  tags            = "${var.tags}"
}

module "target_group" {
  source            = "git::ssh://git@source.sanoma.com:7999/tfmod/lb.git//modules/target_group?ref=0.0.5"
  port              = "${var.target_group_port}"
  instances         = "${module.instance.ids}"
  instance_count    = "${module.instance.count}"
  security_group_id = "${module.loadbalancer.security_group_id}"
  tags              = "${var.tags}"
}

module "listener_http" {
  source           = "git::ssh://git@source.sanoma.com:7999/tfmod/lb.git//modules/listener?ref=0.0.5"
  port             = "${var.listener_http_port}"
  target_group_arn = "${module.target_group.target_group_arn}"
  loadbalancer_arn = "${module.loadbalancer.arn}"
}

module "certificate" {
  source = "git::ssh://git@source.sanoma.com:7999/tfmod/acm_certificate.git?ref=0.0.1"
  domain = "${var.lb_certificate_domain}"
}

# module "cf_certificate" {
#   providers {
#     aws = "aws.us-east-1"
#   }

#   source = "git::ssh://git@source.sanoma.com:7999/tfmod/acm_certificate.git?ref=0.0.1"
#   domain = "sanoma.tech"
# }

module "listener_https" {
  source             = "git::ssh://git@source.sanoma.com:7999/tfmod/lb.git//modules/listener_ssl?ref=0.0.5"
  port               = "${var.listener_https_port}"
  target_group_arn   = "${module.target_group.target_group_arn}"
  ssl_certificate_id = "${module.certificate.arn}"
  loadbalancer_arn   = "${module.loadbalancer.arn}"
}

#### RDS ######################################################################

module "db" {
  source                  = "git::ssh://git@source.sanoma.com:7999/tfmod/rds.git?ref=0.0.9"
  instance                = "database"
  name                    = "${var.tags["product"]}"
  engine                  = "${var.engine}"
  engine_version          = "${var.engine_version}"
  multi_az                = "${var.multi_az}"
  instance_class          = "${var.instance_class}"
  allocated_storage       = "${var.allocated_storage}"
  port                    = "${var.port}"
  backup_retention_period = "${var.backup_retention_period}"
  tags                    = "${var.tags}"
  parameters              = ["${var.parameters}"]
}

#### S3 #######################################################################

module "log_bucket" {
#  source            = "git::ssh://git@source.sanoma.com:7999/tfmod/s3_bucket.git?ref=feature/refactor-lifecycle-logging"
  source            = "git::ssh://git@source.sanoma.com:7999/tfmod/s3_bucket.git?ref=0.0.3"
  name              = "logbucket"
  tags              = "${var.tags}"
  acl               = "log-delivery-write"
  lifecycle_enabled = true
  lifecycle_prefix  = "/log"
}

module "web_bucket" {
  source          = "git::ssh://git@source.sanoma.com:7999/tfmod/s3_bucket_with_logging.git?ref=0.0.3"
  name            = "webbucket"
  acl             = "private"
  tags            = "${var.tags}"
  logging_bucket  = "${module.log_bucket.id}"
  logging_prefix  = "/log"
  create_iam_user = "true"
}

#### Cloudfront ###############################################################

module "cloudfront" {
  source                       = "git::ssh://git@source.sanoma.com:7999/tfmod/cloudfront-s3-and-lb.git?ref=0.0.2"
  tags                         = "${var.tags}"
  s3_origin                    = "${module.web_bucket.bucket_domain_name}"
  s3_bucket_id                 = "${module.web_bucket.id}"
  s3_origin_path               = "${var.s3_origin_path}"
  lb_origin                    = "${module.loadbalancer.fqdn}"
  cache_behavior               = "${var.cache_behavior}"
  default_forward_query_string = "true"
  default_forward_cookies      = "all"
  acm_certificate_arn          = "${var.cf_certificate}"

  #acm_certificate_arn         = "${module.cf_certificate.arn}"
}

#### Memcached

module "novelist_memcached" {
  source = "git::ssh://git@source.sanoma.com:7999/tfmod/memcached.git?ref=0.0.1"
  tags = "${var.tags}"
  node_type = "cache.t2.small"
}
