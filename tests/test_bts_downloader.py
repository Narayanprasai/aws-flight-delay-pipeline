import importlib.util
import io
import json
import sys
import os
import zipfile
from unittest.mock import MagicMock, patch
import pytest

BTS_PATH = os.path.join(os.path.dirname(__file__), '..', 'lambda', 'bts_downloader', 'handler.py')

def load_bts_handler():
    spec = importlib.util.spec_from_file_location('bts_handler', BTS_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

def create_test_zip(csv_content):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w') as zf:
        zf.writestr('test_flights.csv', csv_content)
    return buffer.getvalue()

SAMPLE_CSV = 'Year,Month,FlightDate,Origin,Dest\n2025,3,2025-03-01,JFK,LAX\n'

@patch('boto3.client')
@patch('requests.get')
def test_handler_success(mock_get, mock_boto3):
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_response = MagicMock()
    mock_response.content = create_test_zip(SAMPLE_CSV)
    mock_response.raise_for_status = MagicMock()
    mock_get.return_value = mock_response
    mock_s3 = MagicMock()
    mock_boto3.return_value = mock_s3
    handler = load_bts_handler()
    result = handler.handler({'year': 2025, 'month': 3}, {})
    assert result['statusCode'] == 200
    body = json.loads(result['body'])
    assert body['year'] == 2025
    assert body['month'] == 3
    assert 's3_key' in body
    mock_s3.put_object.assert_called_once()

@patch('boto3.client')
@patch('requests.get')
def test_handler_uses_previous_month_when_no_event(mock_get, mock_boto3):
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_response = MagicMock()
    mock_response.content = create_test_zip(SAMPLE_CSV)
    mock_response.raise_for_status = MagicMock()
    mock_get.return_value = mock_response
    mock_s3 = MagicMock()
    mock_boto3.return_value = mock_s3
    handler = load_bts_handler()
    result = handler.handler({}, {})
    assert result['statusCode'] == 200

@patch('requests.get')
def test_handler_raises_on_http_error(mock_get):
    import requests
    os.environ['RAW_BUCKET'] = 'test-bucket'
    mock_get.side_effect = requests.exceptions.HTTPError('404 Not Found')
    handler = load_bts_handler()
    with pytest.raises(requests.exceptions.HTTPError):
        handler.handler({'year': 2025, 'month': 3}, {})

def test_get_previous_month():
    handler = load_bts_handler()
    year, month = handler.get_previous_month()
    assert 2020 <= year <= 2030
    assert 1 <= month <= 12

def test_build_bts_url():
    handler = load_bts_handler()
    url, filename = handler.build_bts_url(2025, 3)
    assert '2025' in url
    assert '3' in url
    assert filename.endswith('.zip')