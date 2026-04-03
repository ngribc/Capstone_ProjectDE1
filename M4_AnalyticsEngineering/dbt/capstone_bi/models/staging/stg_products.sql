{{ config(materialized='view') }}

SELECT
    id::INTEGER                     AS product_id,
    TRIM(title)                     AS product_name,
    price::DOUBLE                   AS price_usd,
    TRIM(LOWER(category))           AS category,
    TRIM("description")             AS description, -- <--- LAS COMILLAS SON LA CLAVE
    thumbnail                       AS image_url, 
    CAST(snapshot_month AS VARCHAR) AS snapshot_month,
    CURRENT_TIMESTAMP               AS dbt_updated_at
FROM {{ source('bronze', 'bronze_products') }} 
WHERE id IS NOT NULL AND price > 0
