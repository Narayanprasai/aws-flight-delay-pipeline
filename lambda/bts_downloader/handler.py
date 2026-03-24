import json
import logging
import os
from datetime import datetime, timedelta

import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET = os.environ["RAW_BUCKET"]
BTS_BASE_URL = "https://transtats.bts.gov/PREZIP"


def get_previous_month():
    today = datetime.utcnow()
    first_of_month = today.replace(day=1)
    last_month = first_of_month - timedelta(days=1)
    return last_month.year, last_month.month


def build_bts_url(year, month):
    filename = (
        f"On_Time_Reporting_Carrier_On_Time_Performance_1987_present"
        f"_{year}_{month}.zip"
    )
    return f"{BTS_BASE_URL}/{filename}", filename


def download_and_upload(url, filename, year, month):
    logger.info(f"Downloading BTS data from {url}")

    response = requests.get(url, timeout=300, stream=True)
    response.raise_for_status()

    s3_key = f"flights/year={year}/month={month:02d}/{filename}"

    s3_client = boto3.client("s3")
    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=response.content,
        ContentType="application/zip",
    )

    logger.info(f"Successfully uploaded to s3://{S3_BUCKET}/{s3_key}")
    return s3_key


def handler(event, context):
    logger.info("BTS downloader Lambda started")
    logger.info(f"Event: {json.dumps(event)}")

    try:
        if "year" in event and "month" in event:
            year = int(event["year"])
            month = int(event["month"])
            logger.info(f"Manual trigger for {year}-{month:02d}")
        else:
            year, month = get_previous_month()
            logger.info(f"Auto trigger for previous month: {year}-{month:02d}")

        url, filename = build_bts_url(year, month)
        s3_key = download_and_upload(url, filename, year, month)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "BTS data downloaded successfully",
                "s3_key": s3_key,
                "year": year,
                "month": month,
            }),
        }

    except requests.exceptions.HTTPError as e:
        logger.error(f"HTTP error downloading BTS data: {e}")
        raise

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise