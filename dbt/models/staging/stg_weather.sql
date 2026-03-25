WITH source AS (
    SELECT *
    FROM {{ source('raw', 'weather') }}
    WHERE station_id IS NOT NULL
      AND timestamp IS NOT NULL
),
cleaned AS (
    SELECT
        station_id                                     AS airport_code,
        timestamp                                      AS observation_timestamp,
        CAST(SUBSTR(timestamp, 1, 10) AS DATE)         AS observation_date,
        CAST(temperature_c AS DOUBLE)                  AS temperature_celsius,
        CAST(wind_speed_kmh AS DOUBLE)                 AS wind_speed_kmh,
        CAST(wind_direction_deg AS DOUBLE)             AS wind_direction_degrees,
        CAST(visibility_m AS DOUBLE)                   AS visibility_meters,
        CAST(visibility_m AS DOUBLE) / 1000            AS visibility_km,
        CASE
            WHEN CAST(wind_speed_kmh AS DOUBLE) >= 50 THEN 'severe'
            WHEN CAST(wind_speed_kmh AS DOUBLE) >= 30 THEN 'moderate'
            WHEN CAST(wind_speed_kmh AS DOUBLE) >= 15 THEN 'light'
            ELSE 'calm'
        END                                            AS wind_severity,
        CASE
            WHEN CAST(visibility_m AS DOUBLE) < 1000  THEN 'very_low'
            WHEN CAST(visibility_m AS DOUBLE) < 5000  THEN 'low'
            WHEN CAST(visibility_m AS DOUBLE) < 9000  THEN 'moderate'
            ELSE 'good'
        END                                            AS visibility_category,
        raw_message,
        year,
        month,
        day
    FROM source
)
SELECT * FROM cleaned