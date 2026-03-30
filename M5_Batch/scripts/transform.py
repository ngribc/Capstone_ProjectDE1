from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_timestamp

spark = SparkSession.builder.appName("transform").getOrCreate()

df = spark.read.parquet("data/lake/tickets")

df_clean = df.select([col(c).alias(c.lower().replace(" ", "_")) for c in df.columns])

df_typed = df_clean.withColumn("created_at", to_timestamp("created_at"))

df_typed.write.mode("overwrite").parquet("data/lake/tickets_clean")

print("Transformación completada")
