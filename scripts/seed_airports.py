import boto3
import requests
import os

BUCKET = f"flight-pipeline-static-013849273657"
S3_KEY = "airports/airports.csv"
URL = "https://davidmegginson.github.io/ourairports-data/airports.csv"


def seed_airports():
    print("Downloading airports.csv from ourairports.com...")
    response = requests.get(URL, timeout=30)
    response.raise_for_status()

    print(f"Downloaded {len(response.content)} bytes")

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=BUCKET,
        Key=S3_KEY,
        Body=response.content,
        ContentType="text/csv",
    )
    print(f"Uploaded to s3://{BUCKET}/{S3_KEY}")


if __name__ == "__main__":
    seed_airports()