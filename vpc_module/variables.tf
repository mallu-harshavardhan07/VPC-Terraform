variable "project" {
    type = string

}
variable "env" {
    type = string
}

variable "vpc_cidr_block"  {
    type = string
  
}

variable "public_cidr_subnet" {
    type = list(string)
  
}
variable "private_cidr_subnet" {
  type = list(string)
}

variable "database_cidr_subnet" {
  type = list(string)
}
variable "is_peering_required" {
  type = bool
  default = false
}