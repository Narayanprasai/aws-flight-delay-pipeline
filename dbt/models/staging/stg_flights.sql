-- stg_flights.sql
-- Cleans and renames raw BTS flight data
-- Source: s3://flight-pipeline-raw-.../flights/

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'flights') }}
    WHERE cancelled = '0.00'  -- exclude cancelled flights
      AND origin IS NOT NULL
      AND dest IS NOT NULL
),

renamed AS (
    SELECT
        -- identifiers
        flightdate                                    AS flight_date,
        reporting_airline                             AS carrier_code,
        tail_number,
        flight_number_reporting_airline               AS flight_number,

        -- route
        origin                                        AS origin_airport,
        dest                                          AS destination_airport,
        CAST(distance AS DOUBLE)                      AS distance_miles,

        -- departure
        crsdeptime                                    AS scheduled_departure_time,
        deptime                                       AS actual_departure_time,
        CAST(depdelay AS DOUBLE)                      AS departure_delay,
        CAST(depdelayminutes AS DOUBLE)               AS departure_delay_minutes,

        -- arrival
        CAST(arrdelay AS DOUBLE)                      AS arrival_delay,
        CAST(arrdelayminutes AS DOUBLE)               AS arrival_delay_minutes,

        -- delay causes
        CAST(carrierdelay AS DOUBLE)                  AS carrier_delay_minutes,
        CAST(weatherdelay AS DOUBLE)                  AS weather_delay_minutes,
        CAST(nasdelay AS DOUBLE)                      AS nas_delay_minutes,
        CAST(securitydelay AS DOUBLE)                 AS security_delay_minutes,
        CAST(lateaircraftdelay AS DOUBLE)             AS late_aircraft_delay_minutes,

        -- partitions
        year,
        month

    FROM source
)

SELECT * FROM renamed