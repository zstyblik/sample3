#!/usr/bin/env python3
"""Unit tests for weather.py."""
from datetime import datetime
from datetime import timezone

import pytest
import weather


def test_create_weather_s3_key():
    """Test that create_weather_s3_key() works as expected."""
    country = "py_country"
    town = "py_town"
    expected = (
        "weather/data/py_country/py_town/2024/10/23/"
        "weather_py_country_py_town_20241023T091820.json"
    )
    dtime = datetime.fromtimestamp(1729675100, timezone.utc)
    result = weather.create_weather_s3_key(dtime, country, town)
    assert result == expected


@pytest.mark.parametrize(
    "tz_shift,expected",
    [
        (7200, "UTC+02:00"),
        (-25200, "UTC-07:00"),
        (-28800, "UTC-08:00"),
        (19800, "UTC+05:30"),
        # Invalid input.
        (19860, "UTC+05:31"),
        # Invalid input.
        (20700, "UTC+05:45"),
    ],
)
def test_tz_shift_to_label(tz_shift, expected):
    """Test that tz_shift_to_label() works as expected."""
    result = weather.tz_shift_to_label(tz_shift)
    assert result == expected
