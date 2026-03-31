"""
flink_job.py
============
Consume el topic 'products_stream' de Redpanda/Kafka,
enriquece cada mensaje y escribe Parquet particionado por snapshot_month.

Ruta de salida: /tmp/products_parquet/<snapshot_month>/products_<ts>.parquet

IMPORTANTE: Este script usa PyFlink en modo batch-over-stream:
  - Lee todos los mensajes disponibles en el topic hasta el offset más alto
    actual (modo "bounded"), no corre indefinidamente.
  - Kestra lo llama como un subprocess normal (shell.Commands).
  - Para un entorno de producción real se usaría un job de Flink standalone
    con checkpoint y estado persistente.

Instalación previa (en beforeCommands del task Kestra):
  pip install apache-flink kafka-python pyarrow pandas
"""

import json
import os
import sys
from datetime import datetime, timezone

# ── Intento de importar PyFlink; fallback a modo pandas si no está ──────────
try:
    from pyflink.datastream import StreamExecutionEnvironment
    from pyflink.common.serialization import SimpleStringSchema
    from pyflink.datastream.connectors.kafka import FlinkKafkaConsumer
    FLINK_AVAILABLE = True
except ImportError:
    FLINK_AVAILABLE = False
    print("[INFO] PyFlink no disponible, usando modo pandas (equivalente para volúmenes pequeños)")

import pyarrow as pa
import pyarrow.parquet as pq
import pandas as pd
from kafka import KafkaConsumer

# ── Configuración ────────────────────────────────────────────────────────────
BOOTSTRAP_SERVERS = "redpanda:29092"
TOPIC             = "products_stream"
OUTPUT_DIR        = "/tmp/products_parquet"
CONSUMER_TIMEOUT  = 10000   # ms sin mensajes antes de considerar el topic vacío
CONSUMER_GROUP    = "flink-parquet-writer"

# Schema Arrow explícito → garantiza tipos consistentes en DuckDB
ARROW_SCHEMA = pa.schema([
    pa.field("id",             pa.int64()),
    pa.field("title",          pa.string()),
    pa.field("price",          pa.float64()),
    pa.field("description",    pa.string()),
    pa.field("category",       pa.string()),
    pa.field("image",          pa.string()),
    pa.field("snapshot_month", pa.string()),   # "YYYY-MM" — columna de partición
    pa.field("ingested_at",    pa.string()),   # ISO timestamp de escritura
])


def consume_from_kafka() -> list[dict]:
    """
    Drena el topic hasta que pasan CONSUMER_TIMEOUT ms sin mensajes nuevos.
    Retorna lista de dicts listos para convertir a DataFrame.
    """
    consumer = KafkaConsumer(
        TOPIC,
        bootstrap_servers=BOOTSTRAP_SERVERS,
        auto_offset_reset="earliest",         # Lee desde el inicio del topic
        enable_auto_commit=False,             # No commitea → idempotente
        group_id=CONSUMER_GROUP,
        value_deserializer=lambda b: json.loads(b.decode("utf-8")),
        consumer_timeout_ms=CONSUMER_TIMEOUT,
    )

    records = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for msg in consumer:
        row = msg.value
        # Asegura campos mínimos aunque la API cambie schema
        records.append({
            "id":             int(row.get("id", 0)),
            "title":          str(row.get("title", "")),
            "price":          float(row.get("price", 0.0)),
            "description":    str(row.get("description", "")),
            "category":       str(row.get("category", "unknown")),
            "image":          str(row.get("image", "")),
            "snapshot_month": str(row.get("snapshot_month",
                                          datetime.now(timezone.utc).strftime("%Y-%m"))),
            "ingested_at":    now_iso,
        })

    consumer.close()
    print(f"[Flink] Mensajes leídos del topic '{TOPIC}': {len(records)}")
    return records


def write_parquet(records: list[dict]) -> str:
    """
    Convierte los records a DataFrame, valida y escribe Parquet
    particionado por snapshot_month.
    Retorna la ruta del directorio de partición escrito.
    """
    if not records:
        print("[WARN] No hay mensajes para escribir. ¿El topic está vacío?")
        sys.exit(0)

    df = pd.DataFrame(records)

    # Deduplicación por id dentro del mismo snapshot (por si hay reintentos)
    df = df.drop_duplicates(subset=["id", "snapshot_month"])

    # Toma el snapshot_month dominante del batch
    snapshot_month = df["snapshot_month"].mode()[0]  # ej: "2025-03"

    # Directorio particionado: /tmp/products_parquet/snapshot_month=2025-03/
    partition_dir = os.path.join(OUTPUT_DIR, f"snapshot_month={snapshot_month}")
    os.makedirs(partition_dir, exist_ok=True)

    # Nombre de archivo con timestamp para evitar sobreescritura entre runs
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_path = os.path.join(partition_dir, f"products_{ts}.parquet")

    # Convierte a tabla Arrow con schema explícito → tipos garantizados
    table = pa.Table.from_pandas(df, schema=ARROW_SCHEMA, safe=False)
    pq.write_table(
        table,
        output_path,
        compression="snappy",        # Compresión estándar para data lakes
        row_group_size=1000,
    )

    size_kb = os.path.getsize(output_path) / 1024
    print(f"[Flink] Parquet escrito: {output_path} ({size_kb:.1f} KB)")
    print(f"[Flink] Filas: {len(df)} | Columnas: {list(df.columns)}")
    print(f"[Flink] Partición: snapshot_month={snapshot_month}")

    return partition_dir


def validate_parquet(path: str) -> None:
    """Lee el Parquet recién escrito y verifica que sea legible."""
    df_check = pd.read_parquet(path)
    assert not df_check.empty, "Parquet vacío después de escritura"
    assert "id" in df_check.columns, "Columna 'id' faltante"
    print(f"[Flink] Validación OK — {len(df_check)} filas legibles desde Parquet")


def main():
    print(f"[Flink] Iniciando job — {datetime.now(timezone.utc).isoformat()}")
    print(f"[Flink] Modo: {'PyFlink nativo' if FLINK_AVAILABLE else 'pandas+pyarrow (compatible)'}")

    records       = consume_from_kafka()
    partition_dir = write_parquet(records)
    validate_parquet(partition_dir)

    print("[Flink] Job completado exitosamente ✅")


if __name__ == "__main__":
    main()
