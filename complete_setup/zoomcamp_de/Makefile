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
