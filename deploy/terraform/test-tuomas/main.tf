
module "web_server" {
  source          = "git::ssh://git@source.sanoma.com:7999/tfmod/ec2.git?ref=feature/multiaccount"
  name            = "webserver"
  tags            = "${var.tags}"
  count           = "${var.instance_count}"
}
