# Project Notes

## Default Pin Mapping

| Component | Arduino Pin |
|---|---|
| Soil-moisture sensor | A0 |
| Water-level sensor | A1 |
| Red LED | 9 |
| Green LED | 8 |
| Motor driver IN1 | 5 |
| Motor driver IN2 | 6 |
| Motor driver ENA | 3 |
| HC-05 RX/TX via SoftwareSerial | 10, 11 |

## Calibration

The soil-moisture threshold is currently `600`. Sensor values vary between modules and soil conditions, so dry and wet readings should be measured before long-term use.

The water-level reading is mapped from `0–1023` to `0–100%`. The pump is allowed to run only when the calculated level is above `20%` in automatic mode.
