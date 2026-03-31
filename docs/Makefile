# =============================================================================
# Makefile — Comandos rápidos para el stack DE Zoomcamp
# Uso: make <comando>
# =============================================================================

.PHONY: up down restart logs ps \
        dbt-run dbt-test dbt-docs \
        kestra redpanda jupyter superset spark \
        reset-duckdb setup

# ── Stack completo ────────────────────────────────────────────────────────────
up:
	docker compose up -d
	@echo ""
	@echo "✅ Stack levantado:"
	@echo "   Kestra:   http://localhost:18080  (admin@kestra.io / Admin1234)"
	@echo "   Jupyter:  http://localhost:8888   (token: zoomcamp)"
	@echo "   Superset: http://localhost:8088   (admin / zoomcamp1234)"
	@echo "   Spark UI: http://localhost:8080"

down:
	docker compose down

restart:
	docker compose down && docker compose up -d

logs:
	docker compose logs -f

ps:
	docker compose ps

# ── Módulos individuales ──────────────────────────────────────────────────────
kestra:
	docker compose up -d kestra redpanda

spark:
	docker compose up -d spark-master spark-worker

jupyter:
	docker compose up -d jupyter

superset:
	docker compose up -d superset

# ── dbt ──────────────────────────────────────────────────────────────────────
dbt-run:
	docker compose run --rm dbt dbt run --profiles-dir /usr/app/dbt

dbt-test:
	docker compose run --rm dbt dbt test --profiles-dir /usr/app/dbt

dbt-docs:
	docker compose run --rm dbt dbt docs generate --profiles-dir /usr/app/dbt
	docker compose run --rm -p 8081:8081 dbt dbt docs serve --port 8081

dbt-debug:
	docker compose run --rm dbt dbt debug --profiles-dir /usr/app/dbt

# ── Utilidades ────────────────────────────────────────────────────────────────
# Borra el DuckDB para empezar de cero (¡cuidado!)
reset-duckdb:
	rm -f ./duckdb/capstone.duckdb
	@echo "DuckDB reseteado"

# Crea todas las carpetas necesarias si no existen
setup:
	mkdir -p flows scripts dbt/capstone_bi/models/{staging,marts} \
	         data storage duckdb notebooks spark
	@echo "Estructura de carpetas creada ✅"
