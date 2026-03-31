-- tests/singular/assert_satisfaction_avg_reasonable.sql
-- The average satisfaction score across all tickets must be between 1.5 and 4.9.
-- Catches data generation bugs (e.g. all tickets getting score=0 or score=99).

SELECT
    ROUND(AVG(satisfaction_score), 2) AS avg_score,
    'avg satisfaction out of expected range [1.5, 4.9]' AS reason
FROM {{ ref('fact_sales_support') }}
HAVING AVG(satisfaction_score) < 1.5
    OR AVG(satisfaction_score) > 4.9
