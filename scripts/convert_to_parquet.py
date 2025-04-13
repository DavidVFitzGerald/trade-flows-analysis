
import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DoubleType

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s]: %(message)s')


parser = argparse.ArgumentParser()
parser.add_argument('--HS_code', required=True)
parser.add_argument('--bucket_name', required=True)

args = parser.parse_args()
HS_code = args.HS_code
bucket_name = args.bucket_name

csv_folder = f"gs://{bucket_name}/csv/{HS_code}"
logging.info(f"Looking for CSV files in {csv_folder}...")

# Find all CSV files starting with 'BACI'
csv_files = list(csv_folder.glob("BACI*.csv"))
if not csv_files:
    raise FileNotFoundError("No CSV files starting with 'BACI' found in the specified folder.")

logging.info(f"Found {len(csv_files)} CSV files. Combining them...")

# Combine all CSV files into a single DataFrame using Spark.
spark = SparkSession.builder.appName("CSVToParquet").getOrCreate()
schema = StructType([
    StructField("t", IntegerType(), True),
    StructField("i", IntegerType(), True),
    StructField("j", IntegerType(), True),
    StructField("k", StringType(), True),
    StructField("v", DoubleType(), True),
    StructField("q", DoubleType(), True),
])

# Read CSV files from the input folder in the GCS bucket
input_path = f"{csv_folder}/BACI*.csv"
df = spark.read.option("header", "true").schema(schema).csv(input_path)

# Rename the columns to the full names contained in the Readme file
column_mapping = {
    "t": "year",
    "i": "exporter",
    "j": "importer",
    "k": "product",
    "v": "value",
    "q": "quantity"
}
for old_col, new_col in column_mapping.items():
    df = df.withColumnRenamed(old_col, new_col)

# Save the DataFrame as a Parquet file
parquet_folder = "parquet"
output_path = f"gs://{bucket_name}/{parquet_folder}/{HS_code}"
df.write.partitionBy('year').parquet(output_path, mode="overwrite")

logging.info(f"CSV files from {input_path} have been converted to Parquet and saved to {output_path}")
