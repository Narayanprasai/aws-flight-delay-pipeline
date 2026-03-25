WITH source AS (
    SELECT *
    FROM {{ source('raw', 'flights') }}
    WHERE cancelled = '0.00'
      AND origin IS NOT NULL
      AND dest IS NOT NULL
),
renamed AS (
    SELECT
        flightdate                                                        AS flight_date,
        reporting_airline                                                 AS carrier_code,
        tail_number,
        flight_number_reporting_airline                                   AS flight_number,
        origin                                                            AS origin_airport,
        dest                                                              AS destination_airport,
        TRY_CAST(NULLIF(TRIM(distance), '') AS DOUBLE)                   AS distance_miles,
        crsdeptime                                                        AS scheduled_departure_time,
        deptime                                                           AS actual_departure_time,
        TRY_CAST(NULLIF(TRIM(depdelay), '') AS DOUBLE)                   AS departure_delay,
        TRY_CAST(NULLIF(TRIM(depdelayminutes), '') AS DOUBLE)            AS departure_delay_minutes,
        TRY_CAST(NULLIF(TRIM(arrdelay), '') AS DOUBLE)                   AS arrival_delay,
        TRY_CAST(NULLIF(TRIM(arrdelayminutes), '') AS DOUBLE)            AS arrival_delay_minutes,
        TRY_CAST(NULLIF(TRIM(carrierdelay), '') AS DOUBLE)               AS carrier_delay_minutes,
        TRY_CAST(NULLIF(TRIM(weatherdelay), '') AS DOUBLE)               AS weather_delay_minutes,
        TRY_CAST(NULLIF(TRIM(nasdelay), '') AS DOUBLE)                   AS nas_delay_minutes,
        TRY_CAST(NULLIF(TRIM(securitydelay), '') AS DOUBLE)              AS security_delay_minutes,
        TRY_CAST(NULLIF(TRIM(lateaircraftdelay), '') AS DOUBLE)          AS late_aircraft_delay_minutes,
        year,
        month
    FROM source
)
SELECT * FROM renamed