variable "az" {
  default = "eu-west-*"
}

#### Instances ###############################################################
variable "instance_type" {
  description = "Type of instance"
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Instance name prefix"
  default     = "web_server"
}

variable "instance_count" {
  description = "Number of instances"
  default     = "1"
}

variable "security_groups" {
  description = "List of additional security groups to add to the instance"
  type        = "list"
  default     = [""]
}

#### Application Load Balancer ################################################

variable "sg_lb_ports" {
  description = "Ports for the load balancer security group"
  default     = "80/tcp,443/tcp"
}

variable "sg_lb_cidr" {
  description = "cidr blocks for the load balancer security group"
  default     = "0.0.0.0/0"
}

variable "target_group_port" {
  description = "Port and protocol for the target group"
  default     = "80/HTTP"
}

variable "listener_http_port" {
  description = "Port and protocol for the lb listener http port"
  default     = "80/HTTP"
}

variable "listener_https_port" {
  description = "Port and protocol for the lb listener https port"
  default     = "443/HTTPS"
}

variable "lb_certificate_domain" {
  description = "ACM certificate for the lb"
  default     = "sanoma.tech"
}

#### RDS ######################################################################

variable "engine" {
  default = "mariadb"
}

variable "engine_version" {
  default = "10.2.11"
}

variable "port" {
  default = "3306"
}

variable "instance_class" {
  default = "db.t2.small"
}

variable "backup_retention_period" {
  default = "7"
}

variable "skip_final_snapshot" {
  default = "true"
}

variable "multi_az" {
  default = "false"
}

variable "allocated_storage" {
  default = "10"
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  default     = []
}

#### Cloudfront ###############################################################

variable "s3_origin_path" {
  default = "/static"
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names), if any, for this distribution"
  type        = "list"
  default     = []
}

variable "cf_certificate" {
  default = "arn:aws:acm:us-east-1:725602922238:certificate/9324a6c9-c785-48a8-b4fa-8002dc57bb32"
}

variable "cache_behavior" {
  default = {
    "behaviors" = [{
      "allowed_methods"        = ["GET", "HEAD"]
      "cached_methods"         = ["GET", "HEAD"]
      "path_pattern"           = "/html/*"
      "viewer_protocol_policy" = "allow-all"

      "forwarded_values" = [{
        "query_string" = false

        "cookies" = [{
          "forward" = "none"
        }]
      }]

      "target_origin_id" = "S3Origin"
      "min_ttl"          = "0"
      "default_ttl"      = "3600"
      "max_ttl"          = "86400"
    },
      {
        "allowed_methods"        = ["GET", "HEAD"]
        "cached_methods"         = ["GET", "HEAD"]
        "path_pattern"           = "/video/*"
        "viewer_protocol_policy" = "allow-all"

        "forwarded_values" = [{
          "query_string" = false

          "cookies" = [{
            "forward" = "none"
          }]
        }]

        "target_origin_id" = "S3Origin"
        "min_ttl"          = "0"
        "default_ttl"      = "3600"
        "max_ttl"          = "86400"
      },
    ]
  }
}
