variable "name" {
  type = string
  default = "testdb"
}   

variable "subnet_groups" {
  type = list(string)
}

variable "username" {
  type = string
  default = "admin"
  sensitive = true
}

variable "password" {
  type = string
  default = "password!"
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "sg" {
  type = list(string)
}