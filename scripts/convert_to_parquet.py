
import argparse

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DoubleType
from pyspark.sql.functions import col


# Parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--HS_code', required=True)
parser.add_argument('--bucket_name', required=True)

args = parser.parse_args()
HS_code = args.HS_code
bucket_name = args.bucket_name

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
csv_folder = f"gs://{bucket_name}/csv/{HS_code}"
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

# Convert the value from thousand USD to USD. This will make the analysis easier to implement.
df = df.withColumn("value", col("value") * 1000)

# Save the DataFrame as a Parquet file
parquet_folder = "parquet"
output_path = f"gs://{bucket_name}/{parquet_folder}/{HS_code}"
df.write.partitionBy('year').parquet(output_path, mode="overwrite")
