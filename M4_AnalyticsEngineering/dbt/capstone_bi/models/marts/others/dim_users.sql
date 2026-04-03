SELECT
    user_id,
    {{ hash_pii('email') }} as hashed_email, -- Seguridad: PII protegida
    country,
    customer_tier (Free/Premium)
FROM {{ ref('stg_users') }}
-- EFECTIVIZA KPI: Segmentación de ingresos. 
-- Permite saber qué país o qué tipo de cliente genera más problemas.
