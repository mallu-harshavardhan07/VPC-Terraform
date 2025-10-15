module "vpc" {
    source = "../vpc_module"
    project = "roboshop"
    env = "dev"
    vpc_cidr_block =  "10.0.0.0/16"
    public_cidr_subnet = ["10.0.1.0/24","10.0.2.0/24"]
    private_cidr_subnet = ["10.0.11.0/24","10.0.12.0/24"]
    database_cidr_subnet = ["10.0.21.0/24","10.0.22.0/24"]
    is_peering_required = true
    
}