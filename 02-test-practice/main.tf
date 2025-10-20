module "create_vpc" {
  source = "../01-vpc-practice-module"
  project = "Roboshop"
  env = "Dev"
  vpc_cidr_block = "10.0.0.0/16"
  public_cidr_subnet = ["10.0.3.0/24","10.0.4.0/24"]
  private_cidr_subnet = ["10.0.13.0/24","10.0.14.0/24"]
  database_cidr_subnet =  ["10.0.23.0/24","10.0.24.0/24"]
  is_peering_required = true


}