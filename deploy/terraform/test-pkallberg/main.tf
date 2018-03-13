#
# Hello World Web Server
#
module "web_server" {
  source = "git::ssh://git@source.sanoma.com:7999/tfmod/ec2.git?ref=feature/multiaccount"
  name   = "webserver"
  tags   = "${var.tags}"
  count  = "${var.instance_count}"
  volume_size = 20
#  vpc_id = "vpc-0e942268"
#  image  = "centos7-201801241238"
}
