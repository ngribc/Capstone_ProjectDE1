# !pip install google-cloud-storage
from google.cloud import storage

def upload_to_gcs(bucket_name, source_file_name, destination_blob_name):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
    print(f"Archivo {source_file_name} subido a {destination_blob_name}.")

# Como Spark guarda varios archivos, tendrías que subir la carpeta o el archivo .parquet específico

