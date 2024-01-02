variable "domain" {
  type = string
}

variable "setSubdomains" {
  type = list(object({
    subdomain = string
    dns_name = string
    zone_id = string
    set_identifier = string
  })) 
}

variable "type" {
  type = string
  default = "A"
}

variable "failover_type" {
  type = string
  default = "PRIMARY"
}
