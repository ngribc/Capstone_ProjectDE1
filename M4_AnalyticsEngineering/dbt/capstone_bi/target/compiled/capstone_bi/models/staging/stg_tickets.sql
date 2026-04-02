

SELECT
    "Ticket ID"::VARCHAR             AS ticket_id,
    "Product ID"::INTEGER            AS product_id,
    TRIM("Product Purchased")        AS product_name_raw,
    "Date of Purchase"::DATE         AS purchase_date,
    TRIM(LOWER("Ticket Type"))       AS issue_type,
    TRIM("Ticket Status")            AS ticket_status,
    "Customer Satisfaction Rating"::DOUBLE AS satisfaction_score,
    "Resolution Time (hrs)"::DOUBLE  AS resolution_time_hrs,
    snapshot_month,
    CURRENT_TIMESTAMP                AS dbt_updated_at
-- Cambiá 'tickets' por 'bronze_tickets'
FROM "capstone"."main"."bronze_tickets" 
WHERE "Ticket ID" IS NOT NULL