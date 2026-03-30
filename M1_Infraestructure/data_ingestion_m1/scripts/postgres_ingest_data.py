import pandas as pd
from sqlalchemy import create_engine
from tqdm.auto import tqdm
import click
import os

@click.command()
@click.option('--pg-user', default='root')
@click.option('--pg-pass', default='root')
@click.option('--pg-host', default='pgdatabase')
@click.option('--pg-port', default='5432')
@click.option('--pg-db', default='tickets_db')
@click.option('--target-table', default='stg_tickets')
@click.option('--chunksize', default=50000)
def main(pg_user, pg_pass, pg_host, pg_port, pg_db, target_table, chunksize):

    engine = create_engine(
        f'postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}'
    )

    file = "data/customer_support_tickets.csv"

    if not os.path.exists(file):
        raise Exception("CSV no encontrado en /data")

    df_iter = pd.read_csv(file, iterator=True, chunksize=chunksize)

    first_chunk = next(df_iter)

    # crear tabla
    first_chunk.head(0).to_sql(target_table, engine, if_exists="replace")
    print("Tabla creada")

    # guardar parquet (bronze)
    first_chunk.to_parquet("data/tickets_chunk.parquet", engine="pyarrow")

    # insertar primer chunk
    first_chunk.to_sql(target_table, engine, if_exists="append")

    for df_chunk in tqdm(df_iter):
        df_chunk.to_sql(target_table, engine, if_exists="append")

    print("Ingesti√≥n completa Ì∫Ä")

if __name__ == "__main__":
    main()
