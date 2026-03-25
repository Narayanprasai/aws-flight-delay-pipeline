import importlib.util
import json
import os
from unittest.mock import MagicMock, patch
import pytest

NOAA_PATH = os.path.join(os.path.dirname(__file__), '..', 'lambda', 'noaa_fetcher', 'handler.py')

def load_noaa_handler():
    spec = importlib.util.spec_from_file_location('noaa_handler', NOAA_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

SAMPLE_OBSERVATION = {
    'type': 'FeatureCollection',
    'features': [{
        'properties': {
            'timestamp': '2026-03-24T23:50:00+00:00',
            'temperature': {'value': 10.5},
            'windSpeed': {'value': 25.0},
            'windDirection': {'value': 180},
            'visibility': {'value': 16000},
            'presentWeather': [],
            'rawMessage': 'METAR KJFK 242350Z 18014KT'
        }
    }]
}

@patch('boto3.client')
@patch('requests.get')
def test_handler_success(mock_get, mock_boto3):
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = SAMPLE_OBSERVATION
    mock_response.raise_for_status = MagicMock()
    mock_get.return_value = mock_response
    mock_s3 = MagicMock()
    mock_boto3.return_value = mock_s3
    handler = load_noaa_handler()
    result = handler.handler({}, {})
    assert result['statusCode'] == 200
    body = json.loads(result['body'])
    assert body['total_stations'] == 20
    assert body['stations_success'] > 0

@patch('boto3.client')
@patch('requests.get')
def test_handler_skips_404_stations(mock_get, mock_boto3):
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_response = MagicMock()
    mock_response.status_code = 404
    mock_get.return_value = mock_response
    mock_s3 = MagicMock()
    mock_boto3.return_value = mock_s3
    handler = load_noaa_handler()
    result = handler.handler({}, {})
    assert result['statusCode'] == 200
    body = json.loads(result['body'])
    assert body['stations_success'] == 0

@patch('boto3.client')
@patch('requests.get')
def test_handler_continues_on_station_error(mock_get, mock_boto3):
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.side_effect = Exception('API error')
    mock_get.return_value = mock_response
    mock_s3 = MagicMock()
    mock_boto3.return_value = mock_s3
    handler = load_noaa_handler()
    result = handler.handler({}, {})
    assert result['statusCode'] == 200
    body = json.loads(result['body'])
    assert body['stations_failed'] == 20

def test_parse_observation():
    handler = load_noaa_handler()
    feature = SAMPLE_OBSERVATION['features'][0]
    result = handler.parse_observation(feature, 'KJFK')
    assert result['station_id'] == 'KJFK'
    assert result['temperature_c'] == 10.5
    assert result['wind_speed_kmh'] == 25.0
    assert result['visibility_m'] == 16000

def test_get_yesterday():
    handler = load_noaa_handler()
    start, end, yesterday = handler.get_yesterday()
    assert 'T00:00:00Z' in start
    assert 'T23:59:59Z' in end