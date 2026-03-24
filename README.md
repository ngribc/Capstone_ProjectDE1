# 🚀 Data Engineering Project — Batch + Streaming + OLAP (Kimball)

## 📌 Overview

Este proyecto implementa una arquitectura completa de Data Engineering combinando:

- Ingesta batch (CSV)
- Ingesta streaming (API → Kafka)
- Procesamiento en tiempo real (PyFlink)
- Data Warehouse OLAP
- Modelado dimensional (Kimball - Star Schema)
- Orquestación con Kestra

---

## 🧠 Arquitectura General

```mermaid
flowchart TD

A[FakeStore API] --> B[Kafka Producer]
B --> C[Kafka Topic products_stream]

D[CSV Tickets] --> E[Batch Ingestion]

C --> F[PyFlink Streaming ETL]
E --> G[Batch ETL]

F --> H[Parquet Data Lake]
G --> H

H --> I[OLAP Warehouse DuckDB BigQuery]

I --> J[dbt Models STAR Schema]

J --> K[BI Tools Metabase Superset]
```

---

## ⚡ Streaming Architecture

```mermaid
flowchart LR
A[FakeStore API] --> B[Python Producer]
B --> C[(Kafka Broker)]
C --> D[Kafka Topic]
D --> E[PyFlink Job]
E --> F[Transformations]
F --> G[Parquet]
G --> H[(Data Lake)]
```

---

## 🧱 Data Warehouse (Kimball)

```mermaid
flowchart TD
A[(Data Lake)] --> B[Staging]
B --> C[dim_product]
B --> D[dim_category]
B --> E[dim_date]
B --> F[fact_sales]
C --> G[STAR]
D --> G
E --> G
F --> G
```

---

## 🔄 Orquestación (Kestra)

```mermaid
flowchart TD
A[Scheduler] --> B[Producer]
A --> C[Flink]
A --> D[Load DW]
A --> E[dbt]
```

---

## 🛠️ Stack

- Kafka
- PyFlink
- DuckDB / BigQuery
- dbt
- Kestra
- Pandas
- Parquet

---

## 🚀 Cómo correr

```bash
docker-compose up -d
python producer.py
python flink_job.py
duckdb < duckdb_load.sql
dbt run
```

---

## 📈 Futuro

- Data Quality
- SCD Type 2
- Cloud deployment
- Dashboard BI

---

## 👨‍💻 Autor

N.G.
