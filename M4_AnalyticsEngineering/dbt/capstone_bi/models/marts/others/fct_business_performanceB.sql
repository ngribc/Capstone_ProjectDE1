{{ config(materialized='table') }}

WITH metrics AS (
    SELECT 
        ticket_id,
        product_id,
        -- Usamos las columnas reales de tu stg_tickets
        resolution_time_hrs,
        satisfaction_score,
        -- Inventamos un Proxy de Revenue basado en el precio si no tenés tabla de ventas
        -- O simplemente traemos los datos de staging
        snapshot_month
    FROM {{ ref('stg_tickets') }}
)
SELECT 
    t.snapshot_month,
    p.category,
    AVG(t.resolution_time_hrs)      AS avg_resolution_time,
    AVG(t.satisfaction_score)       AS avg_satisfaction,
    COUNT(t.ticket_id)              AS total_tickets
FROM metrics t
LEFT JOIN {{ ref('stg_products') }} p ON t.product_id = p.product_id
GROUP BY 1, 2
