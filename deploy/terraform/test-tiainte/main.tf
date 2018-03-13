#
# My first webserver
#
module "web_server" {
  source          = "git::ssh://git@source.sanoma.com:7999/tfmod/ec2.git?ref=master"
  name            = "webserver"
  tags            = ""
  tags            = "$(var.instance_count)"
}
