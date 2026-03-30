FROM python:3.11-slim
RUN pip install --no-cache-dir dbt-duckdb==1.9.* duckdb==1.2.* pyarrow pandas
WORKDIR /usr/app/dbt
COPY profiles.yml /root/.dbt/profiles.yml
CMD ["dbt", "--version"]
