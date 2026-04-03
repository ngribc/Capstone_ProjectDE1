{{ config(materialized='view') }}

SELECT
    id::INTEGER                    AS user_id,
    username,
    email,
    "firstName"                    AS first_name, -- COMILLAS DOBLES
    "lastName"                     AS last_name,  -- COMILLAS DOBLES
    gender,
    age,
    snapshot_month,
    CURRENT_TIMESTAMP              AS dbt_updated_at
FROM {{ source('bronze', 'bronze_users') }}
WHERE id IS NOT NULL
