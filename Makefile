# =============================================================================
# Makefile — DE Zoomcamp Capstone Project
# FakeStore API × Customer Support Tickets
# Stack: Docker · Kestra · Redpanda · PyFlink · DuckDB · dbt · Superset · Spark
#
# Run from project root:  make <target>
# List all commands:       make help
# =============================================================================

SHELL        := /bin/bash
COMPOSE_FILE := docker-compose.yml
FLOW_NS      := de.project

# Optional overrides (pass on CLI):
#   make kestra-trigger FLOW=csv_full_pipeline
#   make dbt-run MODEL=dim_product
#   make spark-submit JOB=scripts/my_job.py
FLOW  ?= csv_full_pipeline
MODEL ?=
JOB   ?=

.PHONY: help check up down restart ps logs \
        kestra redpanda spark jupyter superset \
        kestra-logs kestra-trigger kestra-flows \
        dbt-debug dbt-run dbt-test dbt-docs dbt-clean \
        flink-run \
        spark-master spark-submit \
        tf-init tf-plan tf-apply tf-destroy \
        reset-duckdb reset-all setup \
        pipeline-full pipeline-streaming pipeline-batch

# =============================================================================
# HELP
# =============================================================================
help:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║         DE Zoomcamp Capstone — make targets              ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "── SETUP ──────────────────────────────────────────────────"
	@echo "  make setup           Create folder structure"
	@echo "  make check           Check prerequisites (docker, terraform)"
	@echo ""
	@echo "── STACK ──────────────────────────────────────────────────"
	@echo "  make up              Start full stack (all modules)"
	@echo "  make down            Stop all containers"
	@echo "  make restart         Down + Up"
	@echo "  make ps              Container status"
	@echo "  make logs            Tail all logs"
	@echo ""
	@echo "── MODULES (individual) ───────────────────────────────────"
	@echo "  make kestra          Start Kestra + Redpanda only"
	@echo "  make spark           Start Spark master + worker"
	@echo "  make jupyter         Start Jupyter"
	@echo "  make superset        Start Superset"
	@echo ""
	@echo "── KESTRA ─────────────────────────────────────────────────"
	@echo "  make kestra-logs     Tail Kestra logs"
	@echo "  make kestra-flows    List flows in namespace $(FLOW_NS)"
	@echo "  make kestra-trigger  Trigger flow  [FLOW=csv_full_pipeline]"
	@echo ""
	@echo "── DBT ────────────────────────────────────────────────────"
	@echo "  make dbt-debug       Test DuckDB connection"
	@echo "  make dbt-run         Run all models  [MODEL=dim_product]"
	@echo "  make dbt-test        Run data quality tests"
	@echo "  make dbt-docs        Generate + serve docs (port 8081)"
	@echo "  make dbt-clean       Remove target/ folder"
	@echo ""
	@echo "── FLINK ──────────────────────────────────────────────────"
	@echo "  make flink-run       Run flink_job.py (Kafka → Parquet)"
	@echo ""
	@echo "── SPARK ──────────────────────────────────────────────────"
	@echo "  make spark-submit    Submit job  [JOB=scripts/my_job.py]"
	@echo ""
	@echo "── TERRAFORM ──────────────────────────────────────────────"
	@echo "  make tf-init         terraform init"
	@echo "  make tf-plan         terraform plan"
	@echo "  make tf-apply        terraform apply"
	@echo "  make tf-destroy      terraform destroy"
	@echo ""
	@echo "── PIPELINES ──────────────────────────────────────────────"
	@echo "  make pipeline-full       Full ETL end-to-end"
	@echo "  make pipeline-streaming  Streaming only (API → Kafka → Parquet)"
	@echo "  make pipeline-batch      Batch only (CSV → DuckDB)"
	@echo ""
	@echo "── UTILS ──────────────────────────────────────────────────"
	@echo "  make reset-duckdb    ⚠️  Delete capstone.duckdb"
	@echo "  make reset-all       ⚠️  Delete DuckDB + Parquet + Kestra storage"
	@echo ""

# =============================================================================
# PREREQUISITES CHECK
# =============================================================================
check:
	@echo "── Checking prerequisites ──"
	@command -v docker      >/dev/null 2>&1 && echo "✅ docker:     $$(docker --version)" || echo "❌ docker not found"
	@docker compose version >/dev/null 2>&1 && echo "✅ compose:    $$(docker compose version)" || echo "❌ docker compose not found"
	@command -v python3     >/dev/null 2>&1 && echo "✅ python3:    $$(python3 --version)" || echo "❌ python3 not found"
	@command -v terraform   >/dev/null 2>&1 && echo "✅ terraform:  $$(terraform version | head -1)" || echo "⚠️  terraform not found (optional)"
	@command -v git         >/dev/null 2>&1 && echo "✅ git:        $$(git --version)" || echo "❌ git not found"
	@test -f .env           && echo "✅ .env found" || echo "⚠️  .env missing — run: cp .env.example .env"
	@test -f ./data/customer_support_tickets.csv \
	    && echo "✅ CSV data found" \
	    || echo "⚠️  data/customer_support_tickets.csv missing — copy your CSV to ./data/"

# =============================================================================
# FOLDER SETUP
# =============================================================================
setup:
	@echo "── Creating project structure ──"
	mkdir -p flows scripts data storage duckdb notebooks spark
	mkdir -p dbt/capstone_bi/models/{staging,marts} dbt/capstone_bi/{seeds,tests}
	mkdir -p terraform/{modules,environments/{dev,prod}}
	@test -f .env || cp .env.example .env 2>/dev/null || \
	    echo -e "KESTRA_USER=admin@kestra.io\nKESTRA_PASS=Admin1234\nSUPERSET_PASS=zoomcamp1234\nSUPERSET_SECRET=zoomcamp_secret_change_in_prod_32chars\nJUPYTER_TOKEN=zoomcamp" > .env
	@echo "✅ Done. Copy your CSV to ./data/ and run: make up"

# =============================================================================
# STACK — full
# =============================================================================
up: check
	@echo "── Building dbt image ──"
	docker compose -f $(COMPOSE_FILE) build dbt --quiet
	@echo "── Starting full stack ──"
	docker compose -f $(COMPOSE_FILE) up -d
	@echo ""
	@echo "✅ Stack is up:"
	@echo "   🌐 Kestra:   http://localhost:18080  →  admin@kestra.io / Admin1234"
	@echo "   📓 Jupyter:  http://localhost:8888   →  token: zoomcamp"
	@echo "   📊 Superset: http://localhost:8088   →  admin / zoomcamp1234"
	@echo "   ⚡ Spark UI: http://localhost:8080"
	@echo ""
	@echo "   Next: make kestra-trigger   or   make pipeline-full"

down:
	docker compose -f $(COMPOSE_FILE) down

restart: down up

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs -f --tail=150

# =============================================================================
# MODULES — individual
# =============================================================================
kestra:
	docker compose -f $(COMPOSE_FILE) up -d kestra redpanda
	@echo "✅ Kestra: http://localhost:18080"

spark:
	docker compose -f $(COMPOSE_FILE) up -d spark-master spark-worker
	@echo "✅ Spark UI: http://localhost:8080"

jupyter:
	docker compose -f $(COMPOSE_FILE) up -d jupyter
	@echo "✅ Jupyter: http://localhost:8888 (token: zoomcamp)"

superset:
	docker compose -f $(COMPOSE_FILE) up -d superset
	@echo "✅ Superset: http://localhost:8088 (admin / zoomcamp1234)"
	@echo "   Connect DuckDB:  duckdb:////shared/duckdb/capstone.duckdb"

# =============================================================================
# KESTRA
# =============================================================================
kestra-logs:
	docker compose -f $(COMPOSE_FILE) logs -f --tail=200 kestra

kestra-flows:
	@docker compose -f $(COMPOSE_FILE) exec kestra \
	    curl -s -u admin@kestra.io:Admin1234 \
	    http://localhost:18080/api/v1/flows/$(FLOW_NS) \
	    | python3 -c "import sys,json; [print(' -', f['id']) for f in json.load(sys.stdin)]" \
	    2>/dev/null || echo "⚠️  Kestra not running. Run: make kestra"

kestra-trigger:
	@echo "── Triggering flow: $(FLOW) ──"
	docker compose -f $(COMPOSE_FILE) exec kestra \
	    curl -s -X POST -u admin@kestra.io:Admin1234 \
	    http://localhost:18080/api/v1/executions/$(FLOW_NS)/$(FLOW) \
	    | python3 -c "import sys,json; d=json.load(sys.stdin); print('Execution ID:', d.get('id','?'), '| State:', d.get('state',{}).get('current','?'))"

# =============================================================================
# DBT
# =============================================================================
dbt-debug:
	docker compose -f $(COMPOSE_FILE) run --rm dbt \
	    dbt debug --profiles-dir /usr/app/dbt

dbt-run:
	@if [ -n "$(MODEL)" ]; then \
	    docker compose -f $(COMPOSE_FILE) run --rm dbt \
	        dbt run --profiles-dir /usr/app/dbt --select $(MODEL); \
	else \
	    docker compose -f $(COMPOSE_FILE) run --rm dbt \
	        dbt run --profiles-dir /usr/app/dbt; \
	fi

dbt-test:
	docker compose -f $(COMPOSE_FILE) run --rm dbt \
	    dbt test --profiles-dir /usr/app/dbt

dbt-docs:
	docker compose -f $(COMPOSE_FILE) run --rm dbt \
	    dbt docs generate --profiles-dir /usr/app/dbt
	docker compose -f $(COMPOSE_FILE) run --rm -p 8081:8081 dbt \
	    dbt docs serve --port 8081 --profiles-dir /usr/app/dbt
	@echo "✅ dbt docs: http://localhost:8081"

dbt-clean:
	docker compose -f $(COMPOSE_FILE) run --rm dbt \
	    dbt clean --profiles-dir /usr/app/dbt

# =============================================================================
# FLINK
# =============================================================================
flink-run:
	@echo "── Running flink_job.py (Kafka → Parquet) ──"
	docker compose -f $(COMPOSE_FILE) exec kestra \
	    python3 /app/scripts/flink_job.py

# =============================================================================
# SPARK
# =============================================================================
spark-submit:
	@test -n "$(JOB)" || (echo "JOB required. Example: make spark-submit JOB=scripts/my_job.py"; exit 1)
	docker compose -f $(COMPOSE_FILE) exec spark-master \
	    /opt/spark/bin/spark-submit \
	    --master spark://spark-master:7077 \
	    /opt/spark/$(JOB)

# =============================================================================
# TERRAFORM
# =============================================================================
tf-init:
	cd terraform && terraform init -upgrade

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve
	@echo "✅ Infrastructure ready. Run: make up"

tf-destroy:
	@echo "⚠️  This will destroy all Terraform-managed resources"
	cd terraform && terraform destroy

# =============================================================================
# PIPELINES — end-to-end shortcuts
# =============================================================================
pipeline-full:
	@echo "── Full ETL pipeline ──"
	@echo "Step 1/4: Streaming (API → Kafka → Parquet)"
	$(MAKE) kestra-trigger FLOW=streaming_pipeline
	@sleep 30
	@echo "Step 2/4: Batch (CSV → DuckDB bronze)"
	$(MAKE) kestra-trigger FLOW=csv_batch_pipeline
	@sleep 15
	@echo "Step 3/4: Warehouse (Parquet → DuckDB bronze → dbt Star Schema)"
	$(MAKE) kestra-trigger FLOW=warehouse_pipeline
	@echo "Step 4/4: dbt tests"
	$(MAKE) dbt-test
	@echo "✅ Full pipeline complete. Open Superset: http://localhost:8088"

pipeline-streaming:
	$(MAKE) kestra-trigger FLOW=streaming_pipeline

pipeline-batch:
	$(MAKE) kestra-trigger FLOW=csv_batch_pipeline

# =============================================================================
# RESET / CLEAN
# =============================================================================
reset-duckdb:
	@echo "⚠️  Deleting ./duckdb/capstone.duckdb ..."
	rm -f ./duckdb/capstone.duckdb
	@echo "Done. Run: make pipeline-full to reload data."

reset-all:
	@echo "⚠️  Deleting DuckDB, Parquet files and Kestra storage ..."
	rm -f  ./duckdb/capstone.duckdb
	rm -rf ./storage/*
	docker compose -f $(COMPOSE_FILE) exec kestra \
	    rm -rf /tmp/products_parquet 2>/dev/null || true
	@echo "Done. Run: make up && make pipeline-full"
