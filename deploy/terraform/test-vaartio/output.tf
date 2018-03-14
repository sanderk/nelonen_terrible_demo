#### Product ##################################################################

output "product" {
  value = "${var.tags["product"]}"
}

#### Instances ################################################################

output "instance_private_ips" {
  value = "${module.instance.private_ips}"
}

#### RDS ######################################################################

output "rds_db_host" {
  value = "${module.db.address}"
}

output "rds_db_name" {
  value = "${module.db.name}"
}

output "rds_db_endpoint" {
  value = "${module.db.endpoint}"
}

output "rds_db_port" {
  value = "${module.db.port}"
}

output "rds_db_username" {
  value = "${module.db.username}"
}

output "rds_db_password" {
  value = "${module.db.password}"
}

#### LB #######################################################################

output "loadbalancer_dns_name" {
  value = "${module.loadbalancer.dns_name}"
}

output "loadbalancer_fqdn" {
  value = "${module.loadbalancer.fqdn}"
}

#### S3 #######################################################################

output "s3_access_key" {
  value = "${module.web_bucket.access_key}"
}

output "s3_iam_user_name" {
  value = "${module.web_bucket.iam_user_name}"
}

output "s3_secret_key" {
  value = "${module.web_bucket.secret_key}"
}

#### Cloudfront ###############################################################

output "cloudfront_id" {
  value = "${module.cloudfront.id}"
}

output "cloudfront_domain_name" {
  value = "${module.cloudfront.domain_name}"
}

#### Memcached

#output "my_own_memcached_output" {
#  value = "This is my message ${module.novelist_memcached.configuration_endpoint}"
#}