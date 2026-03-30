import duckdb

con = duckdb.connect("warehouse/duckdb.db")

con.execute("""
CREATE OR REPLACE TABLE tickets AS
SELECT * FROM read_parquet('data/lake/tickets_clean')
""")

print("Datos cargados en DuckDB")
