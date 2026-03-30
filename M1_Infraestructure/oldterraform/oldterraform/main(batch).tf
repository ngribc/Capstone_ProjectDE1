resource "google_storage_bucket" "data-lake-bucket" {
  name          = "dtc_data_lake_tu-proyecto" # Nombre único
  location      = "US"
  force_destroy = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "trips_data_all"
  location   = "US"
}
