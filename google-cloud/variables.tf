variable "services" {
  type = list(string)
}

variable "project" {
  type = string
}


variable "region" {
  type = string
}

variable "vpc_on_prem" {
  type = string
}

variable "vpc_google" {
  type = string
}

variable "subnet_on_prem" {
  type = string
}

variable "subnet_google" {
  type = string
}

variable "subnet_cidr_on_prem" {
  type = string
}

variable "subnet_cidr_google" {
  type = string
}

variable "router_on_prem" {
  type = string
}

variable "router_google" {
  type = string
}

variable "router_asn_on_prem" {
  type = number
}

variable "router_asn_google" {
  type = number
}

variable "vpn_ha_gwy_on_prem" {
  type = string
}

variable "vpn_ha_gwy_google" {
  type = string
}

variable "tunnels_onprem" {
  type    = list(string)
}

variable "tunnels_google" {
  type    = list(string)
}

variable "secret_message" {
  type = string
}

variable "router_interface_onprem" {
  type    = list(string)
}

variable "router_interface_google" {
  type    = list(string)
}

variable "router_peer_onprem" {
  type    = list(string)
}

variable "router_peer_google" {
  type    = list(string)
}







variable "onprem_router_ip_range" {
  type    = list(string)
}

variable "onprem_router_peer_ip_address" {
  type    = list(string)
}

variable "google_router_ip_range" {
  type    = list(string)
}

variable "google_router_peer_ip_address" {
  type    = list(string)
}

