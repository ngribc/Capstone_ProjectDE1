{{ config(materialized='table') }}
SELECT
    t.ticket_id,
    t.product_id,
    c.category_id,
    t.purchase_date,
    DATE_TRUNC('month', t.purchase_date)   AS purchase_month,
    p.product_name,
    p.category,
    p.price_usd,
    p.price_segment,
    t.issue_type,
    t.ticket_status,
    t.satisfaction_score,
    CASE WHEN LOWER(t.ticket_status) = 'closed' THEN 1 ELSE 0 END AS is_resolved,
    1.0                                    AS resolution_time_hrs,
    t.snapshot_month,
    t.dbt_updated_at
FROM {{ ref('stg_tickets') }}  t
JOIN {{ ref('dim_product') }}  p ON t.product_id = p.product_id
JOIN {{ ref('dim_category') }} c ON p.category   = c.category_name
