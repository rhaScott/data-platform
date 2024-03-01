import os
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from time import sleep
from typing import Dict, List

import requests
from google.api_core.exceptions import NotFound
from google.cloud import bigquery


class BigQueryConfig:
    def __init__(
        self,
        dataset_id: str,
        table_id: str,
        project_id: str = "data-platform-413021",
        location: str = "EU",
    ):
        self.dataset_id = dataset_id
        self.table_id = table_id
        self.project_id = project_id
        self.location = location
        self.full_table_id = f"{project_id}.{dataset_id}.{table_id}"
        self.full_dataset_id = f"{project_id}.{dataset_id}"


CarbonIntensityBigQueryConfig = BigQueryConfig(
    dataset_id="raw_carbon_intensity",
    table_id="carbon_intensity",
)


class CarbonIntensityApiEndpoint(Enum):
    INTENSITY_DATE = "/intensity/date"


class CarbonIntensityApiConfig:
    base_url: str
    headers: Dict[str, str]
    endpoint: CarbonIntensityApiEndpoint


def get_carbon_intensity(date: str) -> Dict[str, str]:
    headers = {"Accept": "application/json"}
    r = requests.get(
        f"https://api.carbonintensity.org.uk/intensity/date/{date}", headers=headers
    )
    return r.json()["data"]


def create_table_in_bigquery(bq_client, config):

    schema = [
        bigquery.SchemaField("from", "TIMESTAMP"),
        bigquery.SchemaField("to", "TIMESTAMP"),
        bigquery.SchemaField(
            "intensity",
            "RECORD",
            fields=[
                bigquery.SchemaField("forecast", "INTEGER"),
                bigquery.SchemaField("actual", "INTEGER"),
                bigquery.SchemaField("index", "STRING"),
            ],
        ),
    ]

    dataset = bigquery.Dataset(config.full_dataset_id)
    dataset.location = config.location
    try:
        bq_client.get_dataset(dataset)
    except NotFound:
        bq_client.create_dataset(dataset)

    table = bigquery.Table(config.full_table_id, schema=schema)
    try:
        bq_client.get_table(table)
    except NotFound:
        bq_client.create_table(table)


def insert_data_to_table(bq_client, full_table_id: str, data: List[Dict[str, str]]):

    while True:  # weird async buggy behaviour
        try:
            bq_client.get_table(full_table_id)
            print("Table ready.")
            break
        except NotFound:
            print("Table not ready yet. Waiting for 5 seconds...")
            time.sleep(5)

    errors = bq_client.insert_rows_json(full_table_id, data)
    if errors:
        print("Encountered errors while inserting rows: {}".format(errors))
    else:
        print("Rows inserted successfully.")


def main():
    data = get_carbon_intensity("2021-01-01")
    bq_client = bigquery.Client(
        project=CarbonIntensityBigQueryConfig.project_id,
    )
    create_table_in_bigquery(bq_client, CarbonIntensityBigQueryConfig)
    insert_data_to_table(bq_client, CarbonIntensityBigQueryConfig.full_table_id, data)


if __name__ == "__main__":
    main()
