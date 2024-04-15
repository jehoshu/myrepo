variable "ami_id" {
    type = string
    description = "The ID of the AMI to use"
}

variable "instance_type" {
    type = string
    description = "The type of the ec2 instance to create"
}

variable "vault_sub_domain" {
    type = string
    description = "vault sub domain"
}

variable "monitor_sub_domain" {
    type = string
    description = "Monitor_sub_domain"
}


variable "task_id" {
    type = string
    description = "Task_id"
}

variable "task_date" {
    type = string
    description = "Task date format : YYYY-MM-DD"
}

variable "customer_name" {
    type = string
    description = "Customer_name"
}


variable "security_group_ids" {
    type = string
    description = "list of SG ids to associate with the ec2"
}

variable "private_subnets" {
    type = list(string)

}

variable "password" {
    type = string
    description = "123456!@#$Abcd"
    sensitive = true
}

variable "private_domain_name" {
    type = string
}

variable "vault_token" {
    type = string
    sensitive = true
}

variable "kafka_bootstrap_servers" {
    type = string
}

variable environment {
    type = string
}
