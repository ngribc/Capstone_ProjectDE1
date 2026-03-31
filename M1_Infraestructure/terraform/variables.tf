variable "project_name"            { type = string; default = "zoomcamp" }
variable "environment"             { type = string; default = "dev" }
variable "network_name"            { type = string; default = "zoomcamp_net" }
variable "kestra_username"         { type = string; default = "admin@kestra.io" }
variable "kestra_password"         { type = string; sensitive = true; default = "Admin1234" }
variable "superset_secret_key"     { type = string; sensitive = true; default = "zoomcamp_secret_change_in_prod_32chars!!" }
variable "superset_admin_password" { type = string; sensitive = true; default = "zoomcamp1234" }
variable "jupyter_token"           { type = string; sensitive = true; default = "zoomcamp" }
variable "duckdb_filename"         { type = string; default = "capstone.duckdb" }
variable "spark_worker_memory"     { type = string; default = "1G" }
variable "spark_worker_cores"      { type = number; default = 2 }
variable "table_id_batch" {
  description = "Nombre de la tabla para los tickets de soporte"
  type        = string
  default     = "customer_service_tickets"
}

variable "table_id_streaming" {
  description = "Nombre de la tabla para los productos de la API"
  type        = string
  default     = "fake_store_products"
}
