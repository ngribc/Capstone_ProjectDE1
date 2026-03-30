-- models/marts/dim_product.sql
-- Gold: dimensión de productos (SCD tipo 1 — última versión gana)

{{ config(materialized='table') }}

SELECT
    product_id,
    product_name,
    price_usd,
    category,
    description,
    image_url,
    -- Segmento de precio para KPIs
    CASE
        WHEN price_usd <  20  THEN 'economy'
        WHEN price_usd <  100 THEN 'mid-range'
        ELSE                       'premium'
    END                         AS price_segment,
    MAX(snapshot_month)         AS last_seen_month,   -- mes más reciente
    CURRENT_TIMESTAMP           AS dbt_updated_at

FROM {{ ref('stg_products') }}

GROUP BY
    product_id, product_name, price_usd,
    category, description, image_url
