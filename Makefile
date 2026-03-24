.PHONY: install lint test tf-init tf-plan tf-apply demo

install:
pip install -r lambda/bts_downloader/requirements.txt
pip install -r lambda/noaa_fetcher/requirements.txt
pip install pytest boto3 moto black flake8 sqlfluff pre-commit
pre-commit install

lint:
black lambda/ tests/ scripts/
flake8 lambda/ tests/ scripts/
sqlfluff lint dbt/models/ --dialect sparksql

test:
pytest tests/ -v --tb=short

tf-init:
cd terraform && terraform init

tf-plan:
cd terraform && terraform plan

tf-apply:
cd terraform && terraform apply -auto-approve

demo:
python scripts/seed_airports.py
python scripts/backfill_demo.py
