variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc" {
  type = object({
    name    = string
    cidr    = string
    subnets = list(string)
    azs     = list(string)
  })
}

variable "core_network_id" {
  type = string
}

variable "core_network_arn" {
  type = string
}

variable "cw_attach" {
  type = string
}
