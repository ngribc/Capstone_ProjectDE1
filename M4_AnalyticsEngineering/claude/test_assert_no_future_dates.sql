-- tests/singular/assert_no_future_purchase_dates.sql
-- No ticket should have a purchase_date in the future.
-- Catches date parsing bugs in stg_tickets.

SELECT
    ticket_id,
    purchase_date,
    CURRENT_DATE AS today,
    'purchase_date is in the future' AS reason
FROM {{ ref('fact_sales_support') }}
WHERE purchase_date > CURRENT_DATE
