Project Overview: 

El proyecto consiste en el desarrollo de una plataforma de análisis en tiempo real para el seguimiento de tickets de servicio y órdenes de una tienda virtual (basada en la  **Fake Store API** ). El sistema integra flujos de datos continuos, procesa eventos en tiempo real, almacena registros históricos en la nube y proporciona herramientas de visualización avanzada para la toma de decisiones proactivas en la gestión de clientes y logística.

Problem Statement

**El Desafío:** Los sistemas tradicionales de atención al cliente a menudo operan con datos estáticos o reportes diarios, lo que genera cuellos de botella, tiempos de respuesta lentos ante incidentes críticos y una desconexión entre el inventario real y las reclamaciones de los usuarios.

Solución Propuesta:

* **Ingestión de API en Tiempo Real:** **Captura de datos de pedidos y tickets mediante productores de Kafka sincronizados con la Fake Store API.**
* **Procesamiento de Flujos:** **Uso de Spark Streaming y Kestra para identificar anomalías y tendencias en el comportamiento de los servicios al instante.**
* **Almacenamiento de Datos de Niveles:** **Implementación de una arquitectura de medallón (Bronze, Silver, Gold) para asegurar la integridad de los datos.**
* **Dashboards Dinámicos:** **Visualización de métricas clave (SLA, volumen de tickets, estados de envío) mediante Superset.**

Project Architecture Overview

La arquitectura se centra en un flujo de datos sin interrupciones, orquestado por contenedores **Docker** y gestionado por  **Kestra** . Los eventos de la Fake Store API son capturados por un productor, enviados a un tópico de Kafka y procesados a través de pipelines de Spark para su transformación y posterior análisis en BigQuery.

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
- Superset

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

# Capstone Project DE1 — FakeStore API × Customer Support Tickets

> **Stack:** Docker · Terraform · Kestra · Redpanda · PyFlink · DuckDB · dbt · Spark · Superset · Jupyter

Two data sources, one Star Schema, end-to-end ETL pipeline.

---

## Quick Start

**Prerequisites:** `docker`, `docker compose`, `git`. Terraform optional.

```bash
# 1. Clone and enter the project
git clone https://github.com/ngribc/Capstone_ProjectDE1.git
cd Capstone_ProjectDE1

# 2. Copy your CSV to ./data/ and start the stack
cp /path/to/customer_support_tickets.csv ./data/
make up

# 3. Run the full pipeline
make pipeline-full
```

Open **Superset** at `http://localhost:8088` (admin / zoomcamp1234) and connect DuckDB:
```
duckdb:////shared/duckdb/capstone.duckdb
```

---

## ETL Architecture

### Full Data Flow

```mermaid
flowchart TD
    subgraph SOURCES["📥 Sources"]
        API["FakeStore API\nfakestoreapi.com/products"]
        CSV["Customer Support Tickets\ncustomer_support_tickets.csv"]
    end

    subgraph M2["M2 — Kestra Orchestration"]
        K1["streaming_pipeline\n⏰ cron: 0 23 28-31 * *"]
        K2["csv_batch_pipeline\n⏰ cron: 30 23 28-31 * *"]
        K3["warehouse_pipeline"]
        K4["csv_full_pipeline\norchestrator"]
    end

    subgraph M6["M6 — Streaming"]
        RP["Redpanda\nKafka-compatible\nredpanda:29092"]
        FL["flink_job.py\nPyFlink / pyarrow"]
    end

    subgraph BRONZE["🥉 Bronze — Raw Data"]
        PQ["Parquet Data Lake\n/tmp/products_parquet/\nsnapshot_month=YYYY-MM/"]
        DKB["DuckDB\nbronze_products\nbronze_tickets"]
    end

    subgraph M4["M4 — dbt Analytic Engineering"]
        STG1["stg_products\nsilver view"]
        STG2["stg_tickets\nsilver view"]
        DIM1["dim_product\ngold table"]
        DIM2["dim_category\ngold table"]
        FCT["fact_sales_support\ngold table"]
    end

    subgraph VIZ["M7 — Visualization"]
        SUP["Superset\nDashboards & KPIs"]
        JUP["Jupyter\nNotebooks KPIs"]
    end

    API -->|"HTTP GET"| K1
    K1  -->|"kafka-python\nacks=all"| RP
    RP  -->|"consume topic\nproducts_stream"| FL
    FL  -->|"write snappy parquet\nhive partitioned"| PQ
    CSV -->|"pandas ETL"| K2
    PQ  -->|"read_parquet()\nhive_partitioning=true"| DKB
    K2  -->|"read_csv_auto()"| DKB
    K3  --> DKB
    K4  -->|"subflow"| K1
    K4  -->|"subflow"| K2
    K4  -->|"subflow"| K3
    DKB --> STG1 & STG2
    STG1 --> DIM1 --> FCT
    STG1 --> DIM2 --> FCT
    STG2 --> FCT
    FCT --> SUP & JUP
```

---

### ETL Breakdown — Which ETL did you build?

```mermaid
flowchart LR
    subgraph ETL1["ETL 1 — Streaming"]
        direction TB
        e1["EXTRACT\nKestra HTTP Request\nFakeStore API"]
        t1["TRANSFORM\nkafka-python producer\n+ flink_job.py\n+ snapshot_month tag"]
        l1["LOAD\nParquet Data Lake\n/tmp/products_parquet/"]
        e1 --> t1 --> l1
    end

    subgraph ETL2["ETL 2 — Batch"]
        direction TB
        e2["EXTRACT\nCSV file\ncustomer_support_tickets.csv"]
        t2["TRANSFORM\npandas: dedup\nnormalize columns\nadd snapshot_month"]
        l2["LOAD\nDuckDB\nbronze_tickets"]
        e2 --> t2 --> l2
    end

    subgraph ETL3["ETL 3 — Warehouse / dbt"]
        direction TB
        e3["EXTRACT\nread_parquet() +\nread_csv_auto()\nDuckDB"]
        t3["TRANSFORM\ndbt staging → Silver\ndbt marts → Gold\nStar Schema"]
        l3["LOAD\nfact_sales_support\ndim_product\ndim_category"]
        e3 --> t3 --> l3
    end

    subgraph ETL4["ETL 4 — BI / Dashboard"]
        direction TB
        e4["READ\nDuckDB Gold layer\ncapstone.duckdb"]
        t4["ANALYZE\nKPIs SQL\nJupyter notebooks"]
        l4["VISUALIZE\nSuperset Dashboards\nCharts & Filters"]
        e4 --> t4 --> l4
    end

    ETL1 --> ETL3
    ETL2 --> ETL3
    ETL3 --> ETL4
```

---

### Star Schema (Gold Layer)

```mermaid
erDiagram
    dim_product {
        int product_id PK
        string product_name
        float price_usd
        string category
        string price_segment
        string last_seen_month
    }
    dim_category {
        int category_id PK
        string category_name
        string category_slug
        int total_products
        float avg_price_usd
    }
    fact_sales_support {
        string ticket_id PK
        int product_id FK
        int category_id FK
        date purchase_date
        string issue_type
        string ticket_status
        float satisfaction_score
        int is_resolved
        string snapshot_month
    }
    dim_product ||--o{ fact_sales_support : "product_id"
    dim_category ||--o{ fact_sales_support : "category_id"
```

---

### Difficulty Map

```mermaid
quadrantChart
    title Stack Difficulty vs Business Value
    x-axis Easy --> Hard
    y-axis Low Value --> High Value
    quadrant-1 Do First
    quadrant-2 Core Work
    quadrant-3 Skip
    quadrant-4 Nice to Have
    DuckDB: [0.15, 0.60]
    dbt staging: [0.25, 0.75]
    Kestra flows: [0.35, 0.80]
    Superset: [0.30, 0.70]
    Jupyter KPIs: [0.20, 0.65]
    Redpanda-Kafka: [0.60, 0.85]
    PyFlink-Parquet: [0.75, 0.80]
    Terraform: [0.65, 0.55]
    Spark: [0.80, 0.70]
```

**Easiest path:** DuckDB → dbt → Superset (pure SQL, no infra)  
**Hardest path:** Redpanda → PyFlink → Parquet (distributed streaming)

---

## dbt Models — What Each File Does

### Staging (Silver layer — `materialized: view`)

**`stg_products.sql`**
- **What:** Reads `bronze_products`, casts `id` to INTEGER, `price` to DOUBLE, `LOWER(category)` for normalization, filters `price > 0` and `id IS NOT NULL`.
- **Why:** Raw API data has inconsistent types. This view guarantees clean types before any join downstream.

**`stg_tickets.sql`**
- **What:** Reads `bronze_tickets`, maps `product_purchased` (string) to a `product_id` (1–20) via `HASH % 20 + 1`, casts `customer_satisfaction_rating` to DOUBLE, casts `date_of_purchase` to DATE.
- **Why:** The CSV has no `product_id` column — the hash creates a deterministic FK that joins with `dim_product`. Without this, ETL2 and ETL1 would be siloed.

### Marts (Gold layer — `materialized: table`)

**`dim_product.sql`**
- **What:** `SELECT DISTINCT` from `stg_products`, adds `price_segment` (`economy / mid-range / premium`), takes `MAX(snapshot_month)` to get the latest version of each product.
- **Why:** Dimension table for OLAP. The `price_segment` column enables grouping by tier without SQL `CASE` in every dashboard query.

**`dim_category.sql`**
- **What:** Derives categories from `stg_products` using `GROUP BY category`. Adds `category_id` via `ROW_NUMBER()`, `category_slug` (spaces → underscores), `avg_price_usd` and `total_products` per category.
- **Why:** Superset can filter by category without scanning the fact table. Also pre-computes aggregates for KPI cards.

**`fact_sales_support.sql`**
- **What:** Central join — `stg_tickets JOIN dim_product ON product_id JOIN dim_category ON category`. Adds `is_resolved` (1/0 from ticket_status), `purchase_month` (truncated date), `price_segment` denormalized for OLAP performance.
- **Why:** This is the single table that answers all business questions. One row per ticket, enriched with product and category context. Joining two completely different data sources is the whole point of the capstone.

### Tests (`models/marts/schema.yml`)
- `dim_product.product_id` → `unique` + `not_null`
- `dim_category.category_id` → `unique` + `not_null`
- `fact_sales_support.product_id` → `relationships` to `dim_product`
- `fact_sales_support.category_id` → `relationships` to `dim_category`
- `dim_product.price_segment` → `accepted_values: [economy, mid-range, premium]`

---

## Project Structure

```
Capstone_ProjectDE1/
├── Makefile                          # All commands — run: make help
├── docker-compose.yml                # Full stack: Kestra·Redpanda·dbt·Spark·Jupyter·Superset
├── .env                              # Credentials (generated by terraform or setup)
├── .env.example                      # Template to copy
├── .gitignore
│
├── terraform/                        # M0: Infrastructure as Code
│   ├── main.tf                       # Docker network + volumes + .env generation
│   ├── variables.tf                  # All configurable params (ports, passwords)
│   ├── outputs.tf                    # URLs, resource names after apply
│   └── terraform.tfvars.example      # Copy to terraform.tfvars
│
├── M1_Infraestructure/               # Postgres + pgAdmin (standalone module)
│
├── M2_Orchestration/kestra/
│   └── flows/                        # Kestra flow YMLs
│       ├── streaming_pipeline.yml    # API → Kafka → Parquet (cron: end of month)
│       ├── csv_batch_pipeline.yml    # CSV → DuckDB bronze (cron: end of month +30m)
│       ├── warehouse_pipeline.yml    # Parquet+CSV → DuckDB → dbt run → dbt test
│       └── csv_full_pipeline.yml     # Orchestrator: runs all 3 above in sequence
│
├── M3_DataWarehouse/
│   └── duckdb/
│       └── capstone.duckdb           # Shared file: Kestra writes, dbt transforms, Jupyter reads
│
├── M4_AnalyticsEngineering/
│   └── dbt/
│       ├── Dockerfile                # python:3.11-slim + dbt-duckdb
│       ├── profiles.yml              # target: /shared/duckdb/capstone.duckdb
│       └── capstone_bi/
│           ├── dbt_project.yml       # staging=silver(view), marts=gold(table)
│           └── models/
│               ├── staging/
│               │   ├── sources.yml   # Declares bronze_products, bronze_tickets
│               │   ├── stg_products.sql
│               │   └── stg_tickets.sql
│               └── marts/
│                   ├── schema.yml    # All dbt tests (unique, not_null, relationships)
│                   ├── dim_product.sql
│                   ├── dim_category.sql
│                   └── fact_sales_support.sql
│
├── M5_Batch/
│   ├── notebooks/                    # Jupyter KPI analysis
│   └── spark/                        # Spark job scripts
│
├── M6_Streaming/
│   └── scripts/
│       └── flink_job.py              # Kafka consumer → Parquet writer (pyarrow)
│
├── M7_Visualization/                 # Superset config / exported dashboards
│
└── data/
    └── customer_support_tickets.csv  # ← Copy here before make up
```

---

## Common Commands

```bash
make help              # All available targets
make check             # Verify prerequisites
make up                # Start full stack
make ps                # Container status
make logs              # Live logs

make pipeline-full     # End-to-end ETL in one command
make kestra-trigger    # Trigger a flow  [FLOW=streaming_pipeline]
make dbt-run           # Run all dbt models  [MODEL=dim_product]
make dbt-test          # Data quality tests
make dbt-docs          # Docs at http://localhost:8081

make reset-duckdb      # ⚠️  Wipe DuckDB
make down              # Stop everything
```

---

## Ports

| Service | URL | Credentials |
|---------|-----|-------------|
| Kestra | http://localhost:18080 | admin@kestra.io / Admin1234 |
| Jupyter | http://localhost:8888 | token: zoomcamp |
| Superset | http://localhost:8088 | admin / zoomcamp1234 |
| Spark UI | http://localhost:8080 | — |
| Redpanda | localhost:9092 (Kafka) | — |

Data Flow

1. **Ingestión:** **Un contenedor de streaming extrae datos de la Fake Store API y los envía al tópico de Kafka** `service_ticket_data`.
2. **Procesamiento Batch/Stream:** **Pipeline orquestado por** **Kestra** **que consume datos de Kafka, los almacena como datos** **Bronze** **(raw) en** **Google Cloud Storage (GCS)** **y en una base de datos**  **PostgreSQL** **.**
3. **Transformación (Silver):** **Apache Spark** **procesa los datos de GCS, aplica esquemas OLAP (Star Schema) y los guarda nuevamente en GCS como datos** **Silver** **(transformados).**
4. **Exportación a BigQuery:** **Un pipeline carga los datos "Silver" desde GCS hacia** **BigQuery** **para facilitar el análisis a gran escala.**
5. **Refinamiento de Negocio (Gold):** **dbt Core** **transforma los datos en BigQuery hacia tablas**  **Gold** **, listas para el consumo de analítica avanzada y modelos de machine learning.**

Tech Stack Used

* **Docker:** **Containerización para aislamiento y portabilidad de todos los servicios.**
* **Apache Kafka:** **Plataforma de streaming distribuido para la ingesta de datos.**
* **Kestra:** **Orquestadores para la ejecución de flujos de trabajo y pipelines.**
* **Apache Spark:** **Motor de computación distribuida para procesamiento de datos a gran escala.**
* **dbt (Data Build Tool):** **Transformación de datos SQL para convertir datos crudos en insights.**
* **PostgreSQL:** **Base de datos relacional para almacenamiento operativo y metadatos.**
* **Superset:** **Herramienta de BI para creación de visualizaciones y dashboards.**
* **Google BigQuery & GCS:** **Infraestructura de almacenamiento y Data Warehouse en la nube (GCP).**
* **Terraform:** **Infraestructura como Código (IaC) para el aprovisionamiento de recursos.**

Pipeline Overview

1. **Batch Pipeline:** **Procesa datos históricos desde GCS, realiza transformaciones OLAP con Spark y los exporta a BigQuery.**
2. **Streaming Pipeline:** **Componente dinámico que procesa flujos continuos de la API en tiempo real usando Kafka y Kestra.**
3. **dbt Pipeline:** **Transforma los datos de nivel Silver en tablas Gold dentro de BigQuery, creando modelos de dimensiones y hechos.**
4. **Dockerized Services:** **Gestión de servicios de infraestructura (Broker de Kafka, Zookeeper, Spark Master/Workers, Jupyter, Metabase).**

Step-by-Step Execution Guide

Para ejecutar el proyecto, siga estos pasos tras clonar el repositorio:

1. **Inicialización de Infraestructura:**
   * **Configurar las credenciales de GCP en** `google-cred.json`.
   * **Ejecutar** `terraform-start` **para crear los buckets de GCS y datasets de BigQuery.**
2. **Levantamiento de Servicios:**
   * **Ejecutar** `docker-compose up -d` **para iniciar Kafka, Spark, Postgres y Metabase.**
3. **Activación del Ingestor:**
   * **Ejecutar el script productor:** `python producer_api.py` **para comenzar a poblar Kafka con datos de la Fake Store API.**
4. **Ejecución de Pipelines:**
   * **Acceder a la interfaz de Kestra/Mage para activar el flujo de ingesta y transformación.**
   * **Correr** `dbt run` **para generar las tablas Gold en BigQuery.**
5. **Visualización:**
   * **Conectar Metabase a BigQuery y cargar el archivo de configuración del dashboard predefinido.**

Deliverables

* **Infraestructura:** **Código de Terraform para el despliegue automático en GCP.**
* **Pipelines:** **Scripts de Spark (PySpark) y configuraciones de Kestra/Mage.**
* **Modelos de Datos:** **Repositorio dbt con modelos Gold documentados y testeados.**
* **Dashboard:** **Panel en Metabase con KPIs de Service Ticker (Ej: Tiempo medio de respuesta, Tickets por categoría).**
* **Documentación:** **Guía de depuración (Debug README) y especificación de la arquitectura.**

Additional Benefits

* **Modularidad:** **El diseño permite actualizar componentes individuales (ej. cambiar Spark por Flink) sin afectar el sistema completo.**
* **Costo-Eficiencia:** **Al usar GCS y BigQuery, solo se paga por el almacenamiento y las consultas realizadas.**
* **Escalabilidad Automática:** **La naturaleza distribuida de Kafka y Spark permite manejar incrementos súbitos en el volumen de datos de la API.**

Conclusion

Este proyecto demuestra una implementación robusta de ingeniería de datos moderna. Al integrar tecnologías de punta como Spark, Kafka y dbt bajo una arquitectura de medallón, se logra transformar datos crudos de una API en inteligencia de negocio accionable en tiempo real, garantizando escalabilidad, calidad y mantenibilidad.
