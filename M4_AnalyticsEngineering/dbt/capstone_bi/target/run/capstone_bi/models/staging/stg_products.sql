
  
  create view "capstone"."main_silver"."stg_products__dbt_tmp" as (
    

SELECT
    id::INTEGER                    AS product_id,
    TRIM(title)                    AS product_name,
    price::DOUBLE                  AS price_usd,
    TRIM(LOWER(category))          AS category,
    TRIM(description)              AS description,
    -- thumbnail es el campo que trae DummyJSON por defecto
    thumbnail                      AS image_url, 
    -- snapshot_month viene del script de Python
    CAST(snapshot_month AS VARCHAR) AS snapshot_month,
    CURRENT_TIMESTAMP              AS dbt_updated_at
-- Cambiá 'products' por 'bronze_products'
FROM "capstone"."main"."bronze_products" 
WHERE id IS NOT NULL AND price > 0
  );
