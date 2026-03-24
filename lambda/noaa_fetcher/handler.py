import json
import logging
import os
from datetime import datetime, timedelta

import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET = os.environ["RAW_BUCKET"]
NWS_BASE_URL = "https://api.weather.gov/stations/{station_id}/observations"

AIRPORT_STATIONS = {
    "KJFK": "KJFK",
    "KLAX": "KLAX",
    "KORD": "KORD",
    "KATL": "KATL",
    "KDFW": "KDFW",
    "KDEN": "KDEN",
    "KSFO": "KSFO",
    "KSEA": "KSEA",
    "KLAS": "KLAS",
    "KMCO": "KMCO",
    "KEWR": "KEWR",
    "KPHX": "KPHX",
    "KIAH": "KIAH",
    "KMIA": "KMIA",
    "KBOS": "KBOS",
    "KMSP": "KMSP",
    "KDTW": "KDTW",
    "KPHL": "KPHL",
    "KLGA": "KLGA",
    "KBWI": "KBWI",
}

HEADERS = {
    "User-Agent": "flight-delay-pipeline/1.0 contact@example.com",
    "Accept": "application/geo+json",
}


def get_yesterday():
    yesterday = datetime.utcnow() - timedelta(days=1)
    return yesterday.strftime("%Y-%m-%dT00:00:00Z"), yesterday.strftime("%Y-%m-%dT23:59:59Z"), yesterday


def fetch_station_observations(station_id, start, end):
    url = NWS_BASE_URL.format(station_id=station_id)
    params = {"start": start, "end": end, "limit": 500}

    response = requests.get(url, headers=HEADERS, params=params, timeout=30)

    if response.status_code == 404:
        logger.warning(f"Station {station_id} not found — skipping")
        return []

    response.raise_for_status()
    data = response.json()
    return data.get("features", [])


def parse_observation(feature, station_id):
    props = feature.get("properties", {})
    return {
        "station_id": station_id,
        "timestamp": props.get("timestamp"),
        "temperature_c": props.get("temperature", {}).get("value"),
        "wind_speed_kmh": props.get("windSpeed", {}).get("value"),
        "wind_direction_deg": props.get("windDirection", {}).get("value"),
        "visibility_m": props.get("visibility", {}).get("value"),
        "present_weather": props.get("presentWeather"),
        "raw_message": props.get("rawMessage"),
    }


def handler(event, context):
    logger.info("NOAA fetcher Lambda started")

    start, end, yesterday = get_yesterday()
    date_str = yesterday.strftime("%Y-%m-%d")
    year = yesterday.strftime("%Y")
    month = yesterday.strftime("%m")
    day = yesterday.strftime("%d")

    logger.info(f"Fetching weather observations for {date_str}")

    s3_client = boto3.client("s3")
    success_count = 0
    error_count = 0

    for airport_code, station_id in AIRPORT_STATIONS.items():
        try:
            observations = fetch_station_observations(station_id, start, end)

            if not observations:
                logger.warning(f"No observations for {station_id}")
                continue

            parsed = [parse_observation(f, station_id) for f in observations]

            s3_key = (
                f"weather/year={year}/month={month}/day={day}"
                f"/{station_id}_{date_str}.json"
            )

            s3_client.put_object(
                Bucket=S3_BUCKET,
                Key=s3_key,
                Body=json.dumps(parsed, indent=2),
                ContentType="application/json",
            )

            logger.info(
                f"Uploaded {len(parsed)} observations for "
                f"{station_id} to s3://{S3_BUCKET}/{s3_key}"
            )
            success_count += 1

        except Exception as e:
            logger.error(f"Error fetching {station_id}: {e}")
            error_count += 1
            continue

    result = {
        "date": date_str,
        "stations_success": success_count,
        "stations_failed": error_count,
        "total_stations": len(AIRPORT_STATIONS),
    }

    logger.info(f"Completed: {json.dumps(result)}")
    return {"statusCode": 200, "body": json.dumps(result)}