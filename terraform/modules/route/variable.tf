variable "domain" {
  type = string
}

variable "setSubdomains" {
  type = list(object({
    subdomain = string
    dns_name = string
    zone_id = string
  })) 
}

variable "type" {
  type = string
  default = "A"
}
