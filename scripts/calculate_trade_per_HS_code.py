import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, concat_ws


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
spark = SparkSession.builder.appName("BigQueryTradeGroupedByHSCode").getOrCreate()

# Load the Parquet files from GCS
parquet_folder = "parquet"
input_path = f"gs://{bucket_name}/{parquet_folder}/{HS_code}"
df = spark.read.parquet(input_path)

# Create a table with the total exported value grouped by year, exporter, and HS code
exported_value_by_hs_df = (
    df.groupBy("year", "exporter", "product")
    .sum("value")
    .withColumnRenamed("exporter", "country")
    .withColumnRenamed("sum(value)", "total_exported_value")
)

# Create a table with the total imported value grouped by year, exporter, and HS code
imported_value_by_hs_df = (
    df.groupBy("year", "importer", "product")
    .sum("value")
    .withColumnRenamed("importer", "country")
    .withColumnRenamed("sum(value)", "total_imported_value")
)

# Merge the two tables
merged_df = exported_value_by_hs_df.join(
    imported_value_by_hs_df,
    on=["year", "country", "product"],
    how="outer"
).fillna(0)  # Fill missing values with 0 for countries that only export or import

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

# Load the product codes CSV file
product_codes_path = f"gs://{bucket_name}/csv/{HS_code}/product_codes_*.csv"
product_codes_df = spark.read.option("header", "true").csv(product_codes_path)

# Replace HS codes with "code: description"
product_codes_df = product_codes_df.withColumn(
    "HS_code",
    concat_ws(": ", col("code"), col("description"))
)
merged_df = merged_df.join(
    product_codes_df.select(
        col("code").alias("product"), col("HS_code")
    ),
    on="product",
    how="left"
).drop("product")

# Save the merged table to BigQuery
merged_table_name = f"{bq_dataset_name}.trade_by_hs_code"
temporary_gcs_bucket = f"{bucket_name}/temp"

merged_df.write \
    .format("bigquery") \
    .option("table", merged_table_name) \
    .option("temporaryGcsBucket", temporary_gcs_bucket) \
    .mode("overwrite") \
    .save()

print(f"Merged table grouped by HS code saved to BigQuery: {merged_table_name}")