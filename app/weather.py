#!/usr/bin/env python3
"""Fetch data from API, render it as HTML and store everything on S3.

Fetch weather data from openweathermap API, render it as HTML and store
everything on S3.

2024/10/22 by Zdenek Styblik
"""
import base64
import json
import logging
import os
import sys
import tempfile
from datetime import datetime
from datetime import timezone
from typing import Any
from typing import Dict
from typing import IO

import boto3
import requests
from jinja2 import Environment
from jinja2 import FileSystemLoader
from jinja2 import select_autoescape

AWS_DEFAULT_REGION = "eu-central-1"
HTTP_TIMEOUT = 10  # seconds
SCRIPT_PATH = os.path.dirname(os.path.realpath(__file__))
TEMPLATE_FNAME = os.path.join(SCRIPT_PATH, "templates", "weather.html")
WEATHER_API_URL = "https://api.openweathermap.org"
WEATHER_TOWN = "prague"
WEATHER_COUNTRY = "cz"


def create_weather_s3_key(dtime: datetime, country: str, town: str) -> str:
    """Return S3 key under which weather data will be stored."""
    return (
        "weather/data/{country:s}/{town:s}/{year:s}/{month:s}/{day:s}/"
        "weather_{country:s}_{town:s}_{date:s}.json".format(
            country=country.lower(),
            town=town.lower(),
            year=dtime.strftime("%Y"),
            month=dtime.strftime("%m"),
            day=dtime.strftime("%d"),
            date=dtime.strftime("%Y%m%dT%H%M%S"),
        )
    )


def get_secret_data(secret_name: str, aws_region: str) -> Dict[str, str]:
    """Get data from AWS Secrets Manager.

    Secret data are expected to be JSON. Therefore dict is returned.
    """
    session = boto3.Session()
    secrets_manager = session.client(
        service_name="secretsmanager",
        region_name=aws_region,
    )
    get_secret_value_response = secrets_manager.get_secret_value(
        SecretId=secret_name
    )
    # Decrypts secret using the associated KMS CMK.
    if "SecretString" in get_secret_value_response:
        secret_data = json.loads(get_secret_value_response["SecretString"])
    else:
        decoded_binary_secret = base64.b64decode(
            get_secret_value_response["SecretBinary"]
        )
        secret_data = json.loads(decoded_binary_secret)

    return secret_data


def get_tempfile(*args, **kwargs) -> str:
    """Create tempfile and return its full path."""
    file_desc, fname = tempfile.mkstemp(**kwargs)
    os.fdopen(file_desc).close()
    return fname


def get_weather(
    weather_api_url: str,
    params: Dict[str, Any],
    http_timeout: int = HTTP_TIMEOUT,
) -> Dict[Any, Any]:
    """Query openweathermap API for weather data and return it as dict.

    Expected params:
    * q - in format '<town,cc>'
    * units
    * appid - openweathermap API key
    """
    if "appid" not in params:
        raise KeyError("appid must be given via params")

    url = "{:s}/data/2.5/weather".format(weather_api_url)
    rsp = requests.get(url, params=params, timeout=http_timeout)
    rsp.raise_for_status()
    return rsp.json()


def lambda_handler(event, context):
    """Handle AWS Lambda function invocation by calling main()."""
    main()
    return "done"


def main():
    """Get data from API, generate HTML and store everything on S3."""
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)
    town = os.environ.get("WEATHER_TOWN", WEATHER_TOWN)
    country = os.environ.get("WEATHER_COUNTRY", WEATHER_COUNTRY)
    s3_bucket_name = os.environ.get("WEATHER_S3_BUCKET", None)
    weather_api_url = os.environ.get("WEATHER_API_URL", WEATHER_API_URL)
    # NOTE(zstyblik): Fetch Weather API key either from SSM or ENV.
    sm_secret_name = os.environ.get("WEATHER_SM_SECRET_NAME", None)
    if sm_secret_name:
        aws_region = os.environ.get("AWS_REGION", AWS_DEFAULT_REGION)
        secret_data = get_secret_data(sm_secret_name, aws_region)
        weather_api_key = secret_data["WEATHER_API_KEY"]
    else:
        weather_api_key = os.environ.get("WEATHER_API_KEY", None)

    if not weather_api_key:
        raise ValueError(
            "ENV variable WEATHER_API_KEY with API key must be set"
        )

    params = {
        "q": "{:s},{:s}".format(town, country),
        "units": "metric",
        "appid": weather_api_key,
    }
    weather_data = get_weather(weather_api_url, params)
    logging.debug("Weather data received: '%s'", weather_data)

    dt_now = datetime.now(timezone.utc)
    weather_fname = get_tempfile(suffix=".json", prefix="weather_data")
    logging.info("Weather data filename '%s'", weather_fname)
    weather_s3_key = create_weather_s3_key(dt_now, country, town)
    logging.info("Weather data S3 key '%s'", weather_s3_key)
    try:
        with open(weather_fname, "w", encoding="utf-8") as fhandle:
            json.dump(weather_data, fhandle)

        if s3_bucket_name:
            upload_to_s3(
                weather_fname,
                s3_bucket_name,
                weather_s3_key,
                "application/json",
            )
            os.unlink(weather_fname)
    except Exception:
        os.unlink(weather_fname)
        raise

    # NOTE(zstyblik): original data must be written to disk beyond this point,
    # since it will be modified.
    # NOTE(zstyblik): as per API doc, timestamp and tz offset are in UTC.
    dt_report = datetime.fromtimestamp(int(weather_data["dt"]), timezone.utc)
    weather_data["dt_label"] = dt_report.strftime("%Y-%m-%d %H:%M%z")
    weather_data["timezone_label"] = tz_shift_to_label(
        int(weather_data["timezone"])
    )
    dt_now = datetime.now(timezone.utc)
    weather_data["report_mtime"] = dt_now.strftime("%Y-%m-%d %H:%M:%S%z")

    output_fname = get_tempfile(prefix="index_", suffix=".html")
    logging.info("Output filename '%s'", output_fname)
    try:
        with open(output_fname, "w", encoding="utf-8") as fhandle:
            render_template(weather_data, TEMPLATE_FNAME, fhandle)

        if s3_bucket_name:
            upload_to_s3(
                output_fname, s3_bucket_name, "index.html", "text/html"
            )
            os.unlink(output_fname)
    except Exception:
        os.unlink(output_fname)
        raise


def render_template(
    context: Dict[Any, Any],
    template_fname: str,
    fhandle: IO,
) -> None:
    """Render jinja2 template and write it into fhandle."""
    base_path = os.path.dirname(template_fname)
    logging.debug("Template base path: '%s'.", base_path)
    filename = os.path.basename(template_fname)
    logging.debug("Template file name: '%s'.", filename)
    jinja_env = Environment(
        loader=FileSystemLoader(base_path),
        autoescape=select_autoescape(),
    )
    template = jinja_env.get_template(filename)
    fhandle.write(template.render(context))


def tz_shift_to_label(tz_shift: int) -> str:
    """Convert timezone shift(seconds from UTC) to human readable string."""
    hours = tz_shift // 3600
    minutes = tz_shift % 3600 // 60
    return "UTC{:s}{:02d}:{:02d}".format(
        "+" if hours >= 0 else "-",
        abs(hours),
        abs(minutes),
    )


def upload_to_s3(
    fpath: str, s3_bucket: str, s3_key: str, content_type: str
) -> None:
    """Upload given file to S3 Bucket under given S3 Key."""
    session = boto3.Session()
    s3cli = session.client("s3")
    with open(fpath, "rb") as fhandle:
        s3cli.put_object(
            ACL="bucket-owner-full-control",
            Body=fhandle,
            Bucket=s3_bucket,
            Key=s3_key,
            ContentType=content_type,
        )


if __name__ == "__main__":
    # Just to make absolutely sure this isn't lambda fn.
    is_lambda_env = os.environ.get("AWS_EXECUTION_ENV", None)
    if not is_lambda_env:
        main()
