SELECT
    ticket_id,
    customer_id,
    status,
    DATE(created_at) as created_date
FROM tickets
