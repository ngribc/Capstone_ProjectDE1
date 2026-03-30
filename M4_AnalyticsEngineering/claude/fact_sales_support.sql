-- models/marts/fact_sales_support.sql
-- Gold: tabla de hechos central — une productos con tickets de soporte
-- Granularidad: 1 fila por ticket

{{ config(materialized='table') }}

SELECT
    -- Claves
    t.ticket_id,
    t.product_id,
    c.category_id,

    -- Fechas
    t.purchase_date,
    DATE_TRUNC('month', t.purchase_date)     AS purchase_month,   -- para agrupar por mes

    -- Atributos del producto (desnormalizados para performance OLAP)
    p.product_name,
    p.category,
    p.price_usd,
    p.price_segment,

    -- Métricas del ticket
    t.issue_type,
    t.ticket_status,
    t.satisfaction_score,
    t.resolution_time_hrs,

    -- Métricas derivadas
    CASE WHEN t.ticket_status = 'Closed' THEN 1 ELSE 0 END  AS is_resolved,

    -- Costo operativo proxy (tickets × tiempo estimado de resolución)
    -- Se asume 1hr por ticket si resolution_time_hrs es NULL
    COALESCE(t.resolution_time_hrs, 1.0)     AS resolution_time_hrs_imputed,

    -- Partición
    t.snapshot_month,
    t.dbt_updated_at

FROM {{ ref('stg_tickets') }}  t

-- Join con dimensión de productos (inner: solo tickets con producto válido)
JOIN {{ ref('dim_product') }}  p  ON t.product_id  = p.product_id

-- Join con dimensión de categorías
JOIN {{ ref('dim_category') }} c  ON p.category     = c.category_name
