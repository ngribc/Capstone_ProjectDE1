from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("ingest").getOrCreate()

df = spark.read.option("header", True).csv("data/raw/customer_support_tickets.csv")

df.write.mode("overwrite").parquet("data/lake/tickets")

print("Ingesta completada")
