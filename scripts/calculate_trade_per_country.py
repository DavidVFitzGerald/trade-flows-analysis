import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, coalesce, lit


# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--HS_code', required=True)
parser.add_argument('--bucket_name', required=True)
parser.add_argument('--bq_dataset_name', required=True)
args = parser.parse_args()

HS_code = args.HS_code
bucket_name = args.bucket_name
bq_dataset_name = args.bq_dataset_name

# Initialize Spark session
spark = SparkSession.builder.appName("BigQueryTradeSummary").getOrCreate()

# Load the Parquet files from GCS
parquet_folder = "parquet"
input_path = f"gs://{bucket_name}/{parquet_folder}/{HS_code}"
df = spark.read.parquet(input_path)

# Create a table containing the sum of exported value per country
exported_value_df = (
    df.groupBy("year", "exporter")
    .sum("value")
    .withColumnRenamed("exporter", "country")
    .withColumnRenamed("sum(value)", "total_exported_value")
)

# Create a table containing the sum of imported value per country
imported_value_df = (
    df.groupBy("year", "importer")
    .sum("value")
    .withColumnRenamed("importer", "country")
    .withColumnRenamed("sum(value)", "total_imported_value")
)

# Merge the two tables
merged_df = exported_value_df.join(
    imported_value_df,
    on=["year", "country"],
    how="outer"
).fillna(0)  # Fill missing values with 0 for countries that only export or import

# Add a column for trade deficit (exported value - imported value)
merged_df = merged_df.withColumn(
    "trade_deficit",
    col("total_exported_value") - col("total_imported_value")
)

# Load the country codes CSV file
country_codes_path = f"gs://{bucket_name}/csv/{HS_code}/country_codes_*.csv"
country_codes_df = spark.read.option("header", "true").csv(country_codes_path)

# Replace country codes with country names
merged_df = merged_df.join(
    country_codes_df.select(
        col("country_code").alias("country"), col("country_name")
    ),
    on="country",
    how="left"
).drop("country").withColumnRenamed("country_name", "country")

# Save the merged table to BigQuery
merged_table_name = f"{bq_dataset_name}.trade_summary_per_country"
temporary_gcs_bucket = f"{bucket_name}/temp"

merged_df.write \
    .format("bigquery") \
    .option("table", merged_table_name) \
    .option("temporaryGcsBucket", temporary_gcs_bucket) \
    .mode("overwrite") \
    .save()
