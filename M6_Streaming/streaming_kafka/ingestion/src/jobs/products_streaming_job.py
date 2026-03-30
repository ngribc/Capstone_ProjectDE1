from pyflink.datastream import StreamExecutionEnvironment, CheckpointingMode
from pyflink.table import EnvironmentSettings, StreamTableEnvironment


def main():
    # -------- ENV --------
    env = StreamExecutionEnvironment.get_execution_environment()

    # 🔥 PARALLELISM (SCALING)
    env.set_parallelism(2)

    # 🔥 CHECKPOINTING (EXACTLY-ONCE)
    env.enable_checkpointing(10000)
    env.get_checkpoint_config().set_checkpointing_mode(CheckpointingMode.EXACTLY_ONCE)

    # -------- TABLE ENV --------
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    # -------- SOURCE (REDPANDA) --------
    t_env.execute_sql("""
        CREATE TABLE products_kafka (
            id INT,
            title STRING,
            price DOUBLE,
            category STRING,
            description STRING,
            image STRING,

            ts TIMESTAMP(3) METADATA FROM 'timestamp',
            WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
        ) WITH (
            'connector' = 'kafka',
            'topic' = 'products',
            'properties.bootstrap.servers' = 'redpanda:29092',
            'properties.group.id' = 'flink-products',
            'scan.startup.mode' = 'latest-offset',
            'format' = 'json'
        )
    """)

    # -------- SINK (POSTGRES PRO) --------
    t_env.execute_sql("""
        CREATE TABLE products_aggregated (
            category STRING,
            window_start TIMESTAMP(3),
            window_end TIMESTAMP(3),
            total_products BIGINT,
            avg_price DOUBLE,

            PRIMARY KEY (category, window_start, window_end) NOT ENFORCED
        ) WITH (
            'connector' = 'jdbc',
            'url' = 'jdbc:postgresql://postgres:5432/postgres',
            'table-name' = 'products_aggregated',
            'username' = 'postgres',
            'password' = 'postgres',
            'driver' = 'org.postgresql.Driver',

            -- 🔥 PERFORMANCE
            'sink.buffer-flush.max-rows' = '100',
            'sink.buffer-flush.interval' = '2s',
            'sink.max-retries' = '3'
        )
    """)

    # -------- QUERY (WINDOWING PRO) --------
    t_env.execute_sql("""
        INSERT INTO products_aggregated
        SELECT
            category,
            TUMBLE_START(ts, INTERVAL '1' MINUTE),
            TUMBLE_END(ts, INTERVAL '1' MINUTE),
            COUNT(*) AS total_products,
            AVG(price) AS avg_price
        FROM products_kafka
        WHERE price IS NOT NULL
        GROUP BY
            category,
            TUMBLE(ts, INTERVAL '1' MINUTE)
    """).wait()


if __name__ == "__main__":
    main()