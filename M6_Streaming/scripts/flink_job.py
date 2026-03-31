"""
flink_job.py — Kafka → Parquet Data Lake
Consume 'products_stream' de Redpanda, escribe Parquet particionado por snapshot_month.
"""
import json, os, sys
from datetime import datetime, timezone
import pyarrow as pa
import pyarrow.parquet as pq
import pandas as pd
from kafka import KafkaConsumer

BOOTSTRAP = "redpanda:29092"
TOPIC     = "products_stream"
OUT_DIR   = "/tmp/products_parquet"
TIMEOUT   = 10000

SCHEMA = pa.schema([
    pa.field("id",             pa.int64()),
    pa.field("title",          pa.string()),
    pa.field("price",          pa.float64()),
    pa.field("description",    pa.string()),
    pa.field("category",       pa.string()),
    pa.field("image",          pa.string()),
    pa.field("snapshot_month", pa.string()),
    pa.field("ingested_at",    pa.string()),
])

def consume():
    consumer = KafkaConsumer(
        TOPIC, bootstrap_servers=BOOTSTRAP,
        auto_offset_reset="earliest", enable_auto_commit=False,
        group_id="flink-parquet-writer",
        value_deserializer=lambda b: json.loads(b.decode("utf-8")),
        consumer_timeout_ms=TIMEOUT,
    )
    now = datetime.now(timezone.utc).isoformat()
    records = []
    for msg in consumer:
        r = msg.value
        records.append({
            "id":             int(r.get("id", 0)),
            "title":          str(r.get("title", "")),
            "price":          float(r.get("price", 0.0)),
            "description":    str(r.get("description", "")),
            "category":       str(r.get("category", "unknown")),
            "image":          str(r.get("image", "")),
            "snapshot_month": str(r.get("snapshot_month",
                                        datetime.now(timezone.utc).strftime("%Y-%m"))),
            "ingested_at":    now,
        })
    consumer.close()
    print(f"[Flink] Mensajes leídos: {len(records)}")
    return records

def write_parquet(records):
    if not records:
        print("[WARN] Topic vacío — sin mensajes para escribir")
        sys.exit(0)
    df = pd.DataFrame(records).drop_duplicates(subset=["id", "snapshot_month"])
    snapshot_month = df["snapshot_month"].mode()[0]
    partition_dir = os.path.join(OUT_DIR, f"snapshot_month={snapshot_month}")
    os.makedirs(partition_dir, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    out = os.path.join(partition_dir, f"products_{ts}.parquet")
    table = pa.Table.from_pandas(df, schema=SCHEMA, safe=False)
    pq.write_table(table, out, compression="snappy")
    print(f"[Flink] Escrito: {out} | rows={len(df)}")
    return partition_dir

if __name__ == "__main__":
    print(f"[Flink] Start — {datetime.now(timezone.utc).isoformat()}")
    write_parquet(consume())
    print("[Flink] ✅ Completado")
