SELECT
    ticket_id,
    customer_id,
    created_date,
    status
FROM {{ ref('stg_tickets') }}
