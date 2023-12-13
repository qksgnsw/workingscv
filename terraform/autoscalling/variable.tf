variable "name" {
    type = string
}

variable "env" {
    type = string
}

variable "certificate_arn" {
  type = string
}

variable "user_data" {
    type = string
    default = null
}

variable "tags" {
    type = map(string)
    default = { }
}

variable "min_size" {
    type = number
    default = 1
}

variable "max_size" {
    type = number
    default = 1
}

variable "desired_capacity" {
    type = number
    default = 1
}

variable "vpc_id" {
  type = string
}

variable "alb_subnets" {
  type = list(string)
  default = []
}

variable "vpc_zone_identifier" {
  type        = list(string)
  default     = []
}

variable "image_id" {
    type = string
    default = ""
}

variable "instance_type" {
    type = string
    default = null
}

variable "security_groups" {
    type = list(string)
    default = [ ]
}

