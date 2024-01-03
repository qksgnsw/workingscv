#######################################################################
              # AWS RDS
#######################################################################
# variable "name" {
#   type = string
#   default = "testdb"
# }   

# variable "subnet_groups" {
#   type = list(string)
# }

# variable "username" {
#   type = string
#   default = "admin"
#   sensitive = true
# }

# variable "password" {
#   type = string
#   default = "password!"
#   sensitive = true
# }

# variable "tags" {
#   type = map(string)
#   default = {}
# }

# variable "sg" {
#   type = list(string)
# }

# variable "isReplica" {
#   type = bool
#   default = true
# }

#######################################################################
              # aurora
#######################################################################
# variable "name" {
#   type = string
#   default = "testdb"
# }   
# variable "primary_region" {
#   type = string
# } 
# variable "secondary_region" {
#   type = string
# } 
# variable "primary_vpc" {
#   type = map(string)
#   default = {}
# }   
# variable "secondary_vpc" {
#   type = map(string)
#   default = {}
# }   
# variable "primary_vpc_private_subnets_cidr_blocks" {
#   type = list(string)
#   default = []
# }   
# variable "secondary_vpc_private_subnets_cidr_blocks" {
#   type = list(string)
#   default = []
# }   
# variable "tags" {
#   type = map(string)
#   default = {}
# }