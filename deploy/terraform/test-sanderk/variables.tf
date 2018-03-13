variable "az" {
  default = "eu-west-*"
}

variable "instance_count" {
  type    = "string"
  default = 2
}

variable "timezone" {
  type    = "string"
  default = "Europe/Helsinki"
}