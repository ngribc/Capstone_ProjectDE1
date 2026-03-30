-- models/staging/stg_tickets.sql
-- Silver: limpia y tipifica los tickets Bronze
-- NOTA: ajustá los nombres de columna según tu CSV real.
-- Columnas esperadas del customer_support_tickets.csv:
--   ticket_id, customer_name, product_purchased, date_of_purchase,
--   ticket_type, ticket_subject, ticket_description, ticket_status,
--   resolution, customer_satisfaction_rating

{{ config(materialized='view') }}

SELECT
    -- Identificadores
    ticket_id::VARCHAR                              AS ticket_id,

    -- Relación con productos (join key hacia dim_product)
    -- FakeStore tiene 20 productos con IDs 1-20.
    -- Mapeamos el nombre del producto a su ID usando un hash módulo.
    -- En producción real esto vendría como product_id en el CSV.
    ABS(HASH(TRIM(LOWER(product_purchased)))) % 20 + 1
                                                    AS product_id,
    TRIM(product_purchased)                         AS product_name_raw,

    -- Fechas
    TRY_CAST(date_of_purchase AS DATE)              AS purchase_date,

    -- Tipo de incidencia (para dim_issue_type)
    TRIM(LOWER(ticket_type))                        AS issue_type,
    TRIM(ticket_status)                             AS ticket_status,

    -- Métricas
    TRY_CAST(customer_satisfaction_rating AS DOUBLE) AS satisfaction_score,

    -- Tiempo de resolución en horas (derivado si hay fecha de cierre)
    -- Si el CSV no tiene fecha de cierre, se usa NULL y se imputa después
    NULL::DOUBLE                                    AS resolution_time_hrs,

    snapshot_month,
    CURRENT_TIMESTAMP                               AS dbt_updated_at

FROM {{ source('bronze', 'bronze_tickets') }}

WHERE ticket_id IS NOT NULL
