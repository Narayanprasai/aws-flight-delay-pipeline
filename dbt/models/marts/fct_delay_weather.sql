-- fct_delay_weather.sql
-- Joins flight delays with weather observations
-- This is the core analytical table answering:
-- Which weather conditions correlate most with flight delays?

WITH flights AS (
    SELECT *
    FROM {{ ref('stg_flights') }}
    WHERE arrival_delay_minutes IS NOT NULL
),

weather AS (
    SELECT *
    FROM {{ ref('stg_weather') }}
),

-- get daily weather summary per airport
-- (average across all observations for that day)
daily_weather AS (
    SELECT
        airport_code,
        observation_date,
        AVG(temperature_celsius)    AS avg_temperature_celsius,
        AVG(wind_speed_kmh)         AS avg_wind_speed_kmh,
        MAX(wind_speed_kmh)         AS max_wind_speed_kmh,
        AVG(visibility_meters)      AS avg_visibility_meters,
        MIN(visibility_meters)      AS min_visibility_meters,

        -- use worst conditions of the day
        MAX(CASE wind_severity
            WHEN 'severe'   THEN 4
            WHEN 'moderate' THEN 3
            WHEN 'light'    THEN 2
            ELSE 1
        END)                        AS wind_severity_score,

        MAX(CASE visibility_category
            WHEN 'very_low' THEN 4
            WHEN 'low'      THEN 3
            WHEN 'moderate' THEN 2
            ELSE 1
        END)                        AS visibility_severity_score

    FROM weather
    GROUP BY airport_code, observation_date
),

joined AS (
    SELECT
        -- flight info
        f.flight_date,
        f.carrier_code,
        f.flight_number,
        f.origin_airport,
        f.destination_airport,
        f.distance_miles,

        -- delay metrics
        f.departure_delay_minutes,
        f.arrival_delay_minutes,
        f.weather_delay_minutes,
        f.carrier_delay_minutes,
        f.nas_delay_minutes,

        -- weather at origin airport on flight date
        w.avg_temperature_celsius,
        w.avg_wind_speed_kmh,
        w.max_wind_speed_kmh,
        w.avg_visibility_meters,
        w.min_visibility_meters,
        w.wind_severity_score,
        w.visibility_severity_score,

        -- delay risk score (0-10)
        -- combines weather severity with actual delay
        ROUND(
            LEAST(10,
                (w.wind_severity_score * 1.5) +
                (w.visibility_severity_score * 1.5) +
                (CASE
                    WHEN f.arrival_delay_minutes >= 120 THEN 4
                    WHEN f.arrival_delay_minutes >= 60  THEN 3
                    WHEN f.arrival_delay_minutes >= 30  THEN 2
                    WHEN f.arrival_delay_minutes >= 15  THEN 1
                    ELSE 0
                END)
            )
        , 1)                        AS delay_risk_score,

        -- flag for significant delay
        CASE
            WHEN f.arrival_delay_minutes >= 15 THEN true
            ELSE false
        END                         AS is_significantly_delayed,

        -- partitions
        f.year,
        f.month

    FROM flights f
    LEFT JOIN daily_weather w
        ON f.origin_airport = w.airport_code
        AND CAST(f.flight_date AS DATE) = w.observation_date
)

SELECT * FROM joined