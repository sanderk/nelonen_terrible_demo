#
# Hello World Web Server
#
module "web_server" {
  source = "git::ssh://git@source.sanoma.com:7999/tfmod/ec2.git?ref=master"
  name   = "webserver"
  tags   = "${var.tags}"
  count  = "${var.instance_count}"
  vpc_id = "vpc-0e942268"
}
