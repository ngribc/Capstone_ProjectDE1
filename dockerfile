FROM kestra/kestra:v0.15.0-slim

USER root

# Instalar dependencias de sistema y Python de una vez
RUN apt-get update -qq && \
    apt-get install -y -qq python3 python3-pip python3-venv curl && \
    rm -rf /var/lib/apt/lists/*

# Instalar dbt y librerías
RUN pip install --no-cache-dir dbt-duckdb pyarrow pandas kafka-python requests

# Instalar PLUGINS críticos (incluyendo el Task Runner de procesos)
RUN /app/kestra plugins install \
    io.kestra.plugin:plugin-scripts:LATEST \
    io.kestra.plugin:plugin-jdbc-duckdb:LATEST \
    io.kestra.plugin:plugin-dbt:LATEST \
    io.kestra.plugin:plugin-task-runner-process:LATEST

USER kestra
