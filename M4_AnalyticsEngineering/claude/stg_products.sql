-- models/staging/stg_products.sql
-- Silver: limpia y tipifica los productos Bronze

{{ config(materialized='view') }}

SELECT
    id::INTEGER                         AS product_id,
    TRIM(title)                         AS product_name,
    price::DOUBLE                       AS price_usd,
    TRIM(LOWER(category))               AS category,       -- normaliza a minúsculas
    TRIM(description)                   AS description,
    image                               AS image_url,
    snapshot_month,
    ingested_at::TIMESTAMP              AS ingested_at,
    CURRENT_TIMESTAMP                   AS dbt_updated_at

FROM {{ source('bronze', 'bronze_products') }}

WHERE id IS NOT NULL
  AND price > 0
  AND title IS NOT NULL
