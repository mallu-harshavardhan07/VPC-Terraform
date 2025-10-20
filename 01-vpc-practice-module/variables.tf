variable "project" {
    type = string
    //default = "Roboshop"
}
variable "env" {
    type = string
    //default = "Dev"
}
variable "vpc_cidr_block" {
   type = string
  // default = "10.0.0.0/16"
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
}