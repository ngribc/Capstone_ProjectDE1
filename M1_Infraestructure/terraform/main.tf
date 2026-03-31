terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
    local  = { source = "hashicorp/local",   version = "~> 2.4" }
  }
  backend "local" { path = "./terraform.tfstate" }
}

provider "docker" { host = "unix:///var/run/docker.sock" }

resource "docker_network" "zoomcamp_net" {
  name   = var.network_name
  driver = "bridge"
  labels { label = "project"; value = var.project_name }
  labels { label = "env";     value = var.environment  }
}

resource "docker_volume" "duckdb"          { name = "${var.project_name}_duckdb" }
resource "docker_volume" "superset_home"   { name = "${var.project_name}_superset_home" }
resource "docker_volume" "kestra_storage"  { name = "${var.project_name}_kestra_storage" }

resource "local_file" "env_file" {
  filename        = "${path.module}/../.env"
  file_permission = "0600"
  content = <<-EOT
    # Generado por Terraform — no editar manualmente
    KESTRA_USER=${var.kestra_username}
    KESTRA_PASS=${var.kestra_password}
    SUPERSET_PASS=${var.superset_admin_password}
    SUPERSET_SECRET=${var.superset_secret_key}
    JUPYTER_TOKEN=${var.jupyter_token}
    DUCKDB_FILE=${var.duckdb_filename}
    SPARK_WORKER_MEMORY=${var.spark_worker_memory}
    SPARK_WORKER_CORES=${var.spark_worker_cores}
  EOT
}
resource "google_bigquery_table" "batch_table" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = var.table_id_batch # <--- Acá usás la variable
  deletion_protection = false
}

resource "google_bigquery_table" "streaming_table" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = var.table_id_streaming # <--- Acá usás la otra
  deletion_protection = false
}

