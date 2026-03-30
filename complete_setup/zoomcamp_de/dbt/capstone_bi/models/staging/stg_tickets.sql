{{ config(materialized='view') }}
SELECT
    "ticket_id"::VARCHAR                                            AS ticket_id,
    ABS(HASH(TRIM(LOWER("product_purchased"::VARCHAR)))) % 20 + 1  AS product_id,
    TRIM("product_purchased"::VARCHAR)                              AS product_name_raw,
    TRY_CAST("date_of_purchase" AS DATE)                           AS purchase_date,
    TRIM(LOWER("ticket_type"::VARCHAR))                             AS issue_type,
    TRIM("ticket_status"::VARCHAR)                                  AS ticket_status,
    TRY_CAST("customer_satisfaction_rating" AS DOUBLE)              AS satisfaction_score,
    snapshot_month,
    CURRENT_TIMESTAMP                                               AS dbt_updated_at
FROM {{ source('bronze', 'bronze_tickets') }}
WHERE "ticket_id" IS NOT NULL
