output "network_name"  { value = docker_network.zoomcamp_net.name }
output "duckdb_volume" { value = docker_volume.duckdb.name }
output "urls" {
  value = {
    kestra   = "http://localhost:18080"
    jupyter  = "http://localhost:8888"
    superset = "http://localhost:8088"
    spark    = "http://localhost:8080"
  }
}
output "superset_duckdb_uri" {
  value = "duckdb:////shared/duckdb/${var.duckdb_filename}"
}
