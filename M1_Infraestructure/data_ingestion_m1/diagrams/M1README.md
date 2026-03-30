# Ì∫Ä Data Engineering Module 1 (Production Style)

## Ì∑† Architecture

```mermaid
graph LR
    A[CSV Kaggle] --> B[Ingestion Pipeline]
    B --> C[Parquet Data Lake]
    B --> D[PostgreSQL 18 Staging]
    D --> E[Star Schema OLAP]
    F[pgAdmin UI] --> D
```

## ‚öôÔ∏è Stack

- Docker + Docker Compose
- PostgreSQL 18
- pgAdmin
- Python 3.13 + uv
- Pandas + PyArrow
- SQLAlchemy

## Ì∫Ä Quickstart

```bash
make up
make ingest
```

## Ìºê Access

- pgAdmin: http://localhost:8085  
- user: admin@admin.com  
- pass: root  

