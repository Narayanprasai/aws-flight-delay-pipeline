-- dim_airports.sql
-- Clean airport reference dimension
-- Source: s3://flight-pipeline-static-.../airports/

WITH source AS (
    SELECT *
    FROM {{ source('static', 'airports') }}
    WHERE type IN ('large_airport', 'medium_airport')
      AND iso_country = 'US'
      AND iata_code IS NOT NULL
      AND iata_code != ''
),

cleaned AS (
    SELECT
        iata_code                   AS airport_code,
        name                        AS airport_name,
        municipality                AS city,
        iso_region                  AS state_region,
        CAST(latitude_deg AS DOUBLE) AS latitude,
        CAST(longitude_deg AS DOUBLE) AS longitude,
        elevation_ft,
        type                        AS airport_type
    FROM source
)

SELECT * FROM cleaned