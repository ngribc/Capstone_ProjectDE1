#!/usr/bin/env bash
# =============================================================================
# setup_zoomcamp.sh — Script Maestro DE Zoomcamp Capstone
# =============================================================================
# Crea toda la estructura del proyecto, escribe TODOS los archivos,
# inicializa Terraform y levanta el stack Docker completo.
#
# USO:
#   chmod +x setup_zoomcamp.sh && ./setup_zoomcamp.sh
#
# PREREQUISITOS (en Codespaces ya están instalados):
#   - docker + docker compose
#   - terraform >= 1.6
#   - python3
#   - git
# =============================================================================

set -euo pipefail   # sale en cualquier error

# ── Colores ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${CYAN}  $*${NC}"; \
            echo -e "${BOLD}${CYAN}══════════════════════════════════════════${NC}"; }

# ── Configuración ─────────────────────────────────────────────────────────────
PROJECT_ROOT="${PWD}/zoomcamp_de"
KESTRA_USER="admin@kestra.io"
KESTRA_PASS="Admin1234"
SUPERSET_PASS="zoomcamp1234"
JUPYTER_TOKEN="zoomcamp"
DUCKDB_FILE="capstone.duckdb"

echo -e "${BOLD}"
cat << 'BANNER'
  ╔═══════════════════════════════════════════════════╗
  ║     DE Zoomcamp — Stack Maestro Setup Script      ║
  ║  M1 Docker | M2 Kestra | M3 DuckDB | M4 dbt      ║
  ║  M5 Spark  | M6 Redpanda/Flink | M7 Superset     ║
  ╚═══════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# =============================================================================
# 0. PREREQUISITOS
# =============================================================================
section "0. Verificando prerequisitos"

command -v docker      >/dev/null 2>&1 || err "docker no encontrado"
command -v python3     >/dev/null 2>&1 || err "python3 no encontrado"
log "docker:   $(docker --version | cut -d' ' -f3 | tr -d ',')"
log "python3:  $(python3 --version)"

# Terraform opcional
if command -v terraform >/dev/null 2>&1; then
    log "terraform: $(terraform version -json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])' 2>/dev/null || terraform version | head -1)"
    TF_AVAILABLE=true
else
    warn "terraform no encontrado — se saltea el paso de Terraform (opcional)"
    TF_AVAILABLE=false
fi

# =============================================================================
# 1. ESTRUCTURA DE CARPETAS
# =============================================================================
section "1. Creando estructura de carpetas"

mkdir -p "${PROJECT_ROOT}"/{flows,scripts,data,storage,duckdb,notebooks,spark}
mkdir -p "${PROJECT_ROOT}"/dbt/{capstone_bi/models/{staging,marts},capstone_bi/seeds,capstone_bi/tests}
mkdir -p "${PROJECT_ROOT}"/terraform/{modules,environments/{dev,prod}}
log "Carpetas creadas en: ${PROJECT_ROOT}"

cd "${PROJECT_ROOT}"

# =============================================================================
# 2. DOCKER COMPOSE — Stack universal
# =============================================================================
section "2. Escribiendo docker-compose.yml"

cat > docker-compose.yml << 'EOF'
# Stack Universal DE Zoomcamp — todos los módulos
# Puertos: 18080 Kestra | 8888 Jupyter | 8088 Superset | 8080 Spark | 9092 Redpanda

services:

  # M2 — KESTRA
  kestra:
    image: kestra/kestra:latest
    container_name: kestra
    user: "root"
    privileged: true
    entrypoint:
      - /bin/sh
      - -c
      - |
        apt-get update -qq
        apt-get install -y -qq python3 python3-pip python3-venv curl
        pip install --quiet dbt-duckdb pyarrow pandas kafka-python requests
        /app/kestra server standalone
    ports:
      - "18080:18080"
    environment:
      MICRONAUT_SERVER_PORT: 18080
      KESTRA_CONFIGURATION: |
        kestra:
          server:
            basic-auth:
              enabled: true
              username: "${KESTRA_USER:-admin@kestra.io}"
              password: "${KESTRA_PASS:-Admin1234}"
          repository:
            type: h2
          queue:
            type: h2
          storage:
            type: local
            local:
              base-path: "/app/storage"
    volumes:
      - ./flows:/app/flows
      - ./scripts:/app/scripts
      - ./storage:/app/storage
      - ./dbt:/app/dbt
      - ./duckdb:/shared/duckdb
      - ./data:/shared/data
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      redpanda:
        condition: service_healthy
    networks:
      - zoomcamp_net
    restart: unless-stopped

  # M6 — REDPANDA (Kafka-compatible)
  redpanda:
    image: redpandadata/redpanda:v25.3.9
    container_name: redpanda
    command:
      - redpanda
      - start
      - --smp
      - '1'
      - --reserve-memory
      - 0M
      - --overprovisioned
      - --node-id
      - '1'
      - --kafka-addr
      - PLAINTEXT://0.0.0.0:29092,OUTSIDE://0.0.0.0:9092
      - --advertise-kafka-addr
      - PLAINTEXT://redpanda:29092,OUTSIDE://localhost:9092
      - --pandaproxy-addr
      - PLAINTEXT://0.0.0.0:28082,OUTSIDE://0.0.0.0:8082
      - --advertise-pandaproxy-addr
      - PLAINTEXT://redpanda:28082,OUTSIDE://localhost:8082
      - --rpc-addr
      - 0.0.0.0:33145
      - --advertise-rpc-addr
      - redpanda:33145
    ports:
      - "9092:9092"
      - "29092:29092"
      - "8082:8082"
      - "28082:28082"
    healthcheck:
      test: ["CMD", "rpk", "cluster", "info", "--brokers=localhost:9092"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    networks:
      - zoomcamp_net
    restart: unless-stopped

  # M4 — DBT (on-demand: docker compose run --rm dbt dbt run)
  dbt:
    build:
      context: ./dbt
      dockerfile: Dockerfile
    container_name: dbt
    volumes:
      - ./dbt:/usr/app/dbt
      - ./duckdb:/shared/duckdb
      - ./data:/shared/data
    working_dir: /usr/app/dbt/capstone_bi
    command: ["dbt", "debug", "--profiles-dir", "/usr/app/dbt"]
    networks:
      - zoomcamp_net

  # M5 — SPARK Master (OFICIAL APACHE)
  spark-master:
    image: apache/spark:3.5.1
    container_name: spark-master
    user: root
    # Comando manual para que arranque como Master
    command: /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master
    ports:
      - "8080:8080"
      - "7077:7077"
      - "4040:4040"
    volumes:
      - ./scripts:/opt/spark/scripts
      - ./data:/opt/spark/data
      - ./duckdb:/shared/duckdb
    networks:
      - zoomcamp_net
    restart: unless-stopped

  # M5 — SPARK Worker (OFICIAL APACHE)
  spark-worker:
    image: apache/spark:3.5.1
    container_name: spark-worker
    user: root
    # Comando para que arranque como Worker y se conecte al master
    command: /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
    environment:
      - SPARK_WORKER_MEMORY=1G
      - SPARK_WORKER_CORES=2
    volumes:
      - ./scripts:/opt/spark/scripts
      - ./data:/opt/spark/data
    depends_on:
      - spark-master
    networks:
      - zoomcamp_net
    restart: unless-stopped

  # JUPYTER (KPIs + exploración DuckDB Gold)
  jupyter:
    image: jupyter/scipy-notebook:latest
    container_name: jupyter
    user: root
    environment:
      JUPYTER_ENABLE_LAB: "yes"
      JUPYTER_TOKEN: "${JUPYTER_TOKEN:-zoomcamp}"
      GRANT_SUDO: "yes"
    ports:
      - "8888:8888"
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./duckdb:/shared/duckdb
      - ./data:/shared/data
    command: >
      bash -c "
        pip install --quiet duckdb pyarrow plotly pandas &&
        start-notebook.sh
          --NotebookApp.token='${JUPYTER_TOKEN:-zoomcamp}'
          --NotebookApp.ip='0.0.0.0'
          --NotebookApp.allow_origin='*'
      "
    networks:
      - zoomcamp_net
    restart: unless-stopped

  # M7 — SUPERSET (Dashboards BI)
  superset:
    image: apache/superset:latest
    container_name: superset
    environment:
      SUPERSET_SECRET_KEY: "${SUPERSET_SECRET:-zoomcamp_secret_change_in_prod_32chars}"
    ports:
      - "8088:8088"
    volumes:
      - ./duckdb:/shared/duckdb
      - superset_home:/app/superset_home
    command: >
      bash -c "
        pip install --quiet duckdb-engine duckdb pyarrow &&
        superset db upgrade &&
        (superset fab create-admin
          --username admin --firstname Admin --lastname User
          --email admin@zoomcamp.io
          --password '${SUPERSET_PASS:-zoomcamp1234}'
          2>/dev/null || true) &&
        superset init &&
        superset run -h 0.0.0.0 -p 8088 --with-threads
      "
    networks:
      - zoomcamp_net
    restart: unless-stopped

networks:
  zoomcamp_net:
    driver: bridge

volumes:
  superset_home:
EOF
log "docker-compose.yml creado"

# =============================================================================
# 3. .env
# =============================================================================
section "3. Escribiendo .env"

cat > .env << EOF
KESTRA_USER=${KESTRA_USER}
KESTRA_PASS=${KESTRA_PASS}
SUPERSET_PASS=${SUPERSET_PASS}
SUPERSET_SECRET=zoomcamp_secret_change_in_prod_32chars
JUPYTER_TOKEN=${JUPYTER_TOKEN}
DUCKDB_FILE=${DUCKDB_FILE}
EOF
log ".env creado"

# =============================================================================
# 4. DBT — Dockerfile + profiles + proyecto completo
# =============================================================================
section "4. Escribiendo proyecto dbt"

# Dockerfile
cat > dbt/Dockerfile << 'EOF'
FROM python:3.11-slim
RUN pip install --no-cache-dir dbt-duckdb==1.9.* duckdb==1.2.* pyarrow pandas
WORKDIR /usr/app/dbt
COPY profiles.yml /root/.dbt/profiles.yml
CMD ["dbt", "--version"]
EOF

# profiles.yml
cat > dbt/profiles.yml << 'EOF'
capstone_bi:
  target: prod
  outputs:
    prod:
      type: duckdb
      path: /shared/duckdb/capstone.duckdb
      threads: 4
    dev:
      type: duckdb
      path: /tmp/capstone_dev.duckdb
      threads: 2
EOF

# dbt_project.yml
cat > dbt/capstone_bi/dbt_project.yml << 'EOF'
name: 'capstone_bi'
version: '1.0.0'
config-version: 2
profile: 'capstone_bi'
model-paths: ["models"]
seed-paths:  ["seeds"]
test-paths:  ["tests"]
target-path: "target"
clean-targets: ["target"]
models:
  capstone_bi:
    staging:
      +schema:       silver
      +materialized: view
    marts:
      +schema:       gold
      +materialized: table
EOF

# sources.yml
cat > dbt/capstone_bi/models/staging/sources.yml << 'EOF'
version: 2
sources:
  - name: bronze
    schema: main
    description: "Tablas Bronze cargadas por Kestra"
    tables:
      - name: bronze_products
        columns:
          - name: id
            tests: [not_null]
          - name: snapshot_month
            tests: [not_null]
      - name: bronze_tickets
        columns:
          - name: snapshot_month
            tests: [not_null]
EOF

# stg_products.sql
cat > dbt/capstone_bi/models/staging/stg_products.sql << 'EOF'
{{ config(materialized='view') }}
SELECT
    id::INTEGER                    AS product_id,
    TRIM(title)                    AS product_name,
    price::DOUBLE                  AS price_usd,
    TRIM(LOWER(category))          AS category,
    TRIM(description)              AS description,
    image                          AS image_url,
    snapshot_month,
    CURRENT_TIMESTAMP              AS dbt_updated_at
FROM {{ source('bronze', 'bronze_products') }}
WHERE id IS NOT NULL AND price > 0
EOF

# stg_tickets.sql
cat > dbt/capstone_bi/models/staging/stg_tickets.sql << 'EOF'
{{ config(materialized='view') }}
SELECT
    "ticket_id"::VARCHAR                                            AS ticket_id,
    ABS(HASH(TRIM(LOWER("product_purchased"::VARCHAR)))) % 20 + 1  AS product_id,
    TRIM("product_purchased"::VARCHAR)                              AS product_name_raw,
    TRY_CAST("date_of_purchase" AS DATE)                           AS purchase_date,
    TRIM(LOWER("ticket_type"::VARCHAR))                             AS issue_type,
    TRIM("ticket_status"::VARCHAR)                                  AS ticket_status,
    TRY_CAST("customer_satisfaction_rating" AS DOUBLE)              AS satisfaction_score,
    snapshot_month,
    CURRENT_TIMESTAMP                                               AS dbt_updated_at
FROM {{ source('bronze', 'bronze_tickets') }}
WHERE "ticket_id" IS NOT NULL
EOF

# dim_product.sql
cat > dbt/capstone_bi/models/marts/dim_product.sql << 'EOF'
{{ config(materialized='table') }}
SELECT
    product_id, product_name, price_usd, category, description, image_url,
    CASE
        WHEN price_usd <  20  THEN 'economy'
        WHEN price_usd <  100 THEN 'mid-range'
        ELSE                       'premium'
    END                   AS price_segment,
    MAX(snapshot_month)   AS last_seen_month,
    CURRENT_TIMESTAMP     AS dbt_updated_at
FROM {{ ref('stg_products') }}
GROUP BY product_id, product_name, price_usd, category, description, image_url
EOF

# dim_category.sql
cat > dbt/capstone_bi/models/marts/dim_category.sql << 'EOF'
{{ config(materialized='table') }}
SELECT
    ROW_NUMBER() OVER (ORDER BY category)  AS category_id,
    category                               AS category_name,
    REPLACE(category, ' ', '_')           AS category_slug,
    COUNT(*)                               AS total_products,
    ROUND(AVG(price_usd), 2)              AS avg_price_usd,
    CURRENT_TIMESTAMP                      AS dbt_updated_at
FROM {{ ref('stg_products') }}
WHERE category IS NOT NULL
GROUP BY category
EOF

# fact_sales_support.sql
cat > dbt/capstone_bi/models/marts/fact_sales_support.sql << 'EOF'
{{ config(materialized='table') }}
SELECT
    t.ticket_id,
    t.product_id,
    c.category_id,
    t.purchase_date,
    DATE_TRUNC('month', t.purchase_date)   AS purchase_month,
    p.product_name,
    p.category,
    p.price_usd,
    p.price_segment,
    t.issue_type,
    t.ticket_status,
    t.satisfaction_score,
    CASE WHEN LOWER(t.ticket_status) = 'closed' THEN 1 ELSE 0 END AS is_resolved,
    1.0                                    AS resolution_time_hrs,
    t.snapshot_month,
    t.dbt_updated_at
FROM {{ ref('stg_tickets') }}  t
JOIN {{ ref('dim_product') }}  p ON t.product_id = p.product_id
JOIN {{ ref('dim_category') }} c ON p.category   = c.category_name
EOF

# marts schema.yml (tests)
cat > dbt/capstone_bi/models/marts/schema.yml << 'EOF'
version: 2
models:
  - name: dim_product
    columns:
      - name: product_id
        tests: [unique, not_null]
      - name: price_segment
        tests:
          - accepted_values:
              values: ['economy', 'mid-range', 'premium']
  - name: dim_category
    columns:
      - name: category_id
        tests: [unique, not_null]
      - name: category_name
        tests: [unique, not_null]
  - name: fact_sales_support
    columns:
      - name: ticket_id
        tests: [not_null]
      - name: product_id
        tests:
          - relationships:
              to: ref('dim_product')
              field: product_id
      - name: category_id
        tests:
          - relationships:
              to: ref('dim_category')
              field: category_id
EOF

log "Proyecto dbt completo"

# =============================================================================
# 5. FLOWS KESTRA
# =============================================================================
section "5. Escribiendo Kestra flows"

# streaming_pipeline.yml
cat > flows/streaming_pipeline.yml << 'EOF'
id: streaming_pipeline
namespace: de.project
labels:
  env: dev
  source: fakestore-api
triggers:
  - id: monthly
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 23 28-31 * *"
tasks:
  - id: run_producer
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    beforeCommands:
      - apt-get update -qq && apt-get install -y -qq python3-venv
      - python3 -m venv /tmp/venv_producer
      - /tmp/venv_producer/bin/pip install kafka-python requests --quiet
    retry:
      type: exponential
      interval: PT5S
      maxInterval: PT60S
      maxAttempt: 3
      delayFactor: 2.0
    script: |
      import sys
      sys.path.insert(0, '/tmp/venv_producer/lib/python3.11/site-packages')
      import requests, json
      from datetime import datetime, timezone
      from kafka import KafkaProducer
      from kafka.errors import KafkaError
      snapshot_month = datetime.now(timezone.utc).strftime("%Y-%m")
      data = requests.get("https://fakestoreapi.com/products", timeout=30).json()
      producer = KafkaProducer(
          bootstrap_servers='redpanda:29092',
          value_serializer=lambda v: json.dumps(v).encode('utf-8'),
          acks='all', retries=3, request_timeout_ms=30000
      )
      sent, failed = 0, 0
      for p in data:
          p["snapshot_month"] = snapshot_month
          try:
              producer.send("products_stream", p).get(timeout=10); sent += 1
          except KafkaError as e:
              print(f"[WARN] {e}", file=sys.stderr); failed += 1
      producer.flush(); producer.close()
      print(f"[OK] snapshot={snapshot_month} | sent={sent} | failed={failed}")
      if failed > 0: sys.exit(1)

  - id: run_flink
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    beforeCommands:
      - python3 -m venv /tmp/venv_flink
      - /tmp/venv_flink/bin/pip install pyarrow pandas kafka-python --quiet
    script: |
      import sys, subprocess
      result = subprocess.run(
          ['/tmp/venv_flink/bin/python', '/app/scripts/flink_job.py'],
          text=True
      )
      sys.exit(result.returncode)

  - id: verify_parquet
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - find /tmp/products_parquet -name "*.parquet" -exec ls -lh {} \; 2>/dev/null || echo "No parquet files yet"
EOF

# csv_batch_pipeline.yml
cat > flows/csv_batch_pipeline.yml << 'EOF'
id: csv_batch_pipeline
namespace: de.project
labels:
  env: dev
  type: batch
triggers:
  - id: monthly
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "30 23 28-31 * *"
tasks:
  - id: debug_files
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - echo "=== $(date) ===" && ls -lh /shared/data/ || echo "No data dir"

  - id: transform_csv
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    beforeCommands:
      - apt-get update -qq && apt-get install -y -qq python3-venv
      - python3 -m venv /tmp/venv_batch
      - /tmp/venv_batch/bin/pip install pandas --quiet
    script: |
      import sys
      sys.path.insert(0, '/tmp/venv_batch/lib/python3.11/site-packages')
      import pandas as pd
      from datetime import datetime, timezone
      INPUT  = "/shared/data/customer_support_tickets.csv"
      OUTPUT = "/tmp/clean_tickets.csv"
      snapshot_month = datetime.now(timezone.utc).strftime("%Y-%m")
      try:
          df = pd.read_csv(INPUT)
      except FileNotFoundError:
          print(f"[ERROR] {INPUT} no encontrado", file=sys.stderr); sys.exit(1)
      df.columns = df.columns.str.lower().str.strip().str.replace(' ', '_')
      df = df.drop_duplicates().dropna(how='all')
      str_cols = df.select_dtypes(include='object').columns
      df[str_cols] = df[str_cols].apply(lambda c: c.str.strip())
      df["snapshot_month"] = snapshot_month
      if df.empty:
          print("[ERROR] DataFrame vacío", file=sys.stderr); sys.exit(1)
      df.to_csv(OUTPUT, index=False)
      print(f"[OK] snapshot={snapshot_month} | rows={len(df)}")

  - id: load_duckdb
    type: io.kestra.plugin.jdbc.duckdb.Query
    url: jdbc:duckdb:/shared/duckdb/capstone.duckdb
    sql: |
      CREATE TABLE IF NOT EXISTS bronze_tickets (snapshot_month VARCHAR);
      DELETE FROM bronze_tickets WHERE snapshot_month = strftime(CURRENT_TIMESTAMP, '%Y-%m');
      INSERT INTO bronze_tickets
      SELECT *, strftime(CURRENT_TIMESTAMP, '%Y-%m') AS snapshot_month
      FROM read_csv_auto('/tmp/clean_tickets.csv', header=true, null_padding=true);
      SELECT snapshot_month, COUNT(*) AS n FROM bronze_tickets GROUP BY 1;
EOF

# warehouse_pipeline.yml
cat > flows/warehouse_pipeline.yml << 'EOF'
id: warehouse_pipeline
namespace: de.project
labels:
  env: dev
  layer: warehouse
tasks:
  - id: load_products_bronze
    type: io.kestra.plugin.jdbc.duckdb.Query
    url: jdbc:duckdb:/shared/duckdb/capstone.duckdb
    sql: |
      CREATE TABLE IF NOT EXISTS bronze_products (
          id INTEGER, title VARCHAR, price DOUBLE, description VARCHAR,
          category VARCHAR, image VARCHAR, snapshot_month VARCHAR, ingested_at VARCHAR
      );
      DELETE FROM bronze_products WHERE snapshot_month = strftime(CURRENT_TIMESTAMP, '%Y-%m');
      INSERT INTO bronze_products
      SELECT * FROM read_parquet(
          '/tmp/products_parquet/snapshot_month=*/products_*.parquet',
          hive_partitioning = true
      ) WHERE snapshot_month = strftime(CURRENT_TIMESTAMP, '%Y-%m');
      SELECT snapshot_month, COUNT(*) AS n FROM bronze_products GROUP BY 1;

  - id: load_tickets_bronze
    type: io.kestra.plugin.jdbc.duckdb.Query
    url: jdbc:duckdb:/shared/duckdb/capstone.duckdb
    sql: |
      CREATE TABLE IF NOT EXISTS bronze_tickets (snapshot_month VARCHAR);
      DELETE FROM bronze_tickets WHERE snapshot_month = strftime(CURRENT_TIMESTAMP, '%Y-%m');
      INSERT INTO bronze_tickets
      SELECT *, strftime(CURRENT_TIMESTAMP, '%Y-%m') AS snapshot_month
      FROM read_csv_auto('/shared/data/customer_support_tickets.csv', header=true, null_padding=true);
      SELECT snapshot_month, COUNT(*) AS n FROM bronze_tickets GROUP BY 1;

  - id: dbt_run
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - cd /app/dbt/capstone_bi && dbt run --profiles-dir /app/dbt --target prod

  - id: dbt_test
    type: io.kestra.plugin.scripts.shell.Commands
    taskRunner:
      type: io.kestra.plugin.core.runner.Process
    commands:
      - cd /app/dbt/capstone_bi && dbt test --profiles-dir /app/dbt --target prod

errors:
  - id: on_failure
    type: io.kestra.plugin.core.log.Log
    message: "❌ warehouse_pipeline falló en {{ task.id }} | execution={{ execution.id }}"
EOF

# csv_full_pipeline.yml (orquestador)
cat > flows/csv_full_pipeline.yml << 'EOF'
id: csv_full_pipeline
namespace: de.project
labels:
  env: dev
  type: orchestrator
triggers:
  - id: monthly
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 22 28-31 * *"
tasks:
  - id: streaming
    type: io.kestra.plugin.core.flow.Subflow
    namespace: de.project
    flowId: streaming_pipeline
    wait: true
    transmitFailed: true
  - id: batch
    type: io.kestra.plugin.core.flow.Subflow
    namespace: de.project
    flowId: csv_batch_pipeline
    wait: true
    transmitFailed: true
  - id: warehouse
    type: io.kestra.plugin.core.flow.Subflow
    namespace: de.project
    flowId: warehouse_pipeline
    wait: true
    transmitFailed: true
  - id: done
    type: io.kestra.plugin.core.log.Log
    message: "Pipeline completo ✅ | {{ execution.id }}"
errors:
  - id: on_failure
    type: io.kestra.plugin.core.log.Log
    message: "❌ Falló en {{ task.id }} | {{ execution.id }}"
EOF

log "Flows de Kestra escritos"

# =============================================================================
# 6. FLINK JOB (scripts/flink_job.py)
# =============================================================================
section "6. Escribiendo flink_job.py"

cat > scripts/flink_job.py << 'EOF'
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
EOF
log "flink_job.py escrito"

# =============================================================================
# 7. TERRAFORM
# =============================================================================
section "7. Escribiendo Terraform"

cat > terraform/main.tf << 'EOF'
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
EOF

cat > terraform/variables.tf << 'EOF'
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
EOF

cat > terraform/outputs.tf << 'EOF'
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
EOF

cat > terraform/terraform.tfvars.example << 'EOF'
project_name            = "zoomcamp"
environment             = "dev"
kestra_password         = "Admin1234"
superset_secret_key     = "cambia_esto_32_chars_minimo!!!!!"
superset_admin_password = "zoomcamp1234"
jupyter_token           = "zoomcamp"
EOF

log "Terraform escrito"

# =============================================================================
# 8. MAKEFILE
# =============================================================================
section "8. Escribiendo Makefile"

cat > Makefile << 'EOF'
.PHONY: up down restart logs ps tf-init tf-apply dbt-run dbt-test dbt-docs reset

up:
	docker compose up -d
	@echo ""
	@echo "✅ Stack levantado:"
	@echo "   Kestra:   http://localhost:18080  (admin@kestra.io / Admin1234)"
	@echo "   Jupyter:  http://localhost:8888   (token: zoomcamp)"
	@echo "   Superset: http://localhost:8088   (admin / zoomcamp1234)"
	@echo "   Spark UI: http://localhost:8080"

down:   ; docker compose down
restart:; docker compose down && docker compose up -d
logs:   ; docker compose logs -f
ps:     ; docker compose ps

tf-init:  ; cd terraform && terraform init
tf-apply: ; cd terraform && terraform apply -auto-approve
tf-plan:  ; cd terraform && terraform plan

dbt-run:  ; docker compose run --rm dbt dbt run   --profiles-dir /usr/app/dbt
dbt-test: ; docker compose run --rm dbt dbt test  --profiles-dir /usr/app/dbt
dbt-docs: ; docker compose run --rm dbt dbt docs generate --profiles-dir /usr/app/dbt

reset:
	rm -f ./duckdb/capstone.duckdb
	@echo "DuckDB reseteado ⚠️"
EOF
log "Makefile escrito"

# =============================================================================
# 9. .gitignore
# =============================================================================
section "9. Escribiendo .gitignore"

cat > .gitignore << 'EOF'
# Terraform
terraform/.terraform/
terraform/.terraform.lock.hcl
terraform/terraform.tfstate*
terraform/terraform.tfvars
**/.terraform/
*.tfstate*

# Secrets
.env

# DuckDB
duckdb/*.duckdb
duckdb/*.wal

# dbt
dbt/capstone_bi/target/
dbt/capstone_bi/logs/
dbt/capstone_bi/dbt_packages/

# Kestra state
storage/

# Python
__pycache__/
*.pyc
venv/
.venv/
/tmp/

# Jupyter
**/.ipynb_checkpoints/

# OS
.DS_Store
Thumbs.db
EOF
log ".gitignore escrito"

# =============================================================================
# 10. TERRAFORM — init + apply (si está disponible)
# =============================================================================
section "10. Terraform init & apply"

if [ "$TF_AVAILABLE" = true ]; then
    cd terraform
    info "terraform init..."
    terraform init -upgrade -input=false 2>&1 | tail -5
    info "terraform apply..."
    terraform apply -auto-approve -input=false 2>&1 | tail -10
    cd ..
    log "Terraform: red y volúmenes Docker creados"
else
    warn "Saltando Terraform — creando red Docker manualmente"
    docker network create zoomcamp_net 2>/dev/null || true
    log "Red 'zoomcamp_net' lista"
fi

# =============================================================================
# 11. DOCKER — build + up
# =============================================================================
section "11. Docker Compose — build & up"

info "Building imagen dbt..."
docker compose build dbt 2>&1 | tail -5

info "Levantando stack completo..."
docker compose up -d

# Esperar a que Kestra esté healthy
info "Esperando a que Kestra esté listo (puede tardar ~60s)..."
for i in $(seq 1 24); do
    if curl -sf http://localhost:18080/api/v1/flows > /dev/null 2>&1; then
        log "Kestra listo ✅"
        break
    fi
    echo -n "."
    sleep 5
done

# =============================================================================
# 12. RESUMEN FINAL
# =============================================================================
section "✅ Setup completado"

echo ""
echo -e "${BOLD}Estructura del proyecto:${NC}"
find "${PROJECT_ROOT}" -not -path "*/\.*" -not -path "*/target/*" \
     -not -path "*/storage/*" -not -path "*/__pycache__/*" \
     | sort | head -60 | sed 's|'"${PROJECT_ROOT}"'|.|' | \
     awk '{
       depth = gsub(/\//, "/")
       prefix = ""
       for(i=1; i<depth; i++) prefix = prefix "  "
       print prefix "├── " $0
     }'

echo ""
echo -e "${BOLD}Servicios:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps

echo ""
echo -e "${BOLD}${GREEN}URLs:${NC}"
echo "   🌐 Kestra:   http://localhost:18080  →  admin@kestra.io / Admin1234"
echo "   📓 Jupyter:  http://localhost:8888   →  token: zoomcamp"
echo "   📊 Superset: http://localhost:8088   →  admin / zoomcamp1234"
echo "   ⚡ Spark:    http://localhost:8080"

echo ""
echo -e "${BOLD}Próximos pasos:${NC}"
echo "   1. Copiar CSV:   cp /ruta/a/customer_support_tickets.csv ./data/"
echo "   2. Correr dbt:   make dbt-run"
echo "   3. Ver logs:     make logs"
echo "   4. Conectar Superset a DuckDB:"
echo "      URI: duckdb:////shared/duckdb/capstone.duckdb"
echo ""
echo -e "${BOLD}Comandos rápidos:${NC}  make up | make down | make dbt-run | make dbt-test | make ps"
echo ""
