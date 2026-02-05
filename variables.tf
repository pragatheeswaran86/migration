
variable "org_id" { type = string }
variable "billing_account" { type = string }
variable "project_id" { type = string }
variable "region" { type = string default = "asia-south1" }
variable "network_name" { type = string default = "microservices-vpc" }
variable "subnet_name" { type = string default = "microservices-subnet" }
variable "cluster_name" { type = string default = "microservices-gke" }
