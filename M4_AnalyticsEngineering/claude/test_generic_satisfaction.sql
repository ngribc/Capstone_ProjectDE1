-- tests/generic/satisfaction_between_1_and_5.sql
-- Generic test: asserts satisfaction_score is between 1 and 5 inclusive.
-- Usage in schema.yml:
--   - satisfaction_between_1_and_5

{% test satisfaction_between_1_and_5(model, column_name) %}

SELECT
    {{ column_name }} AS failing_value,
    COUNT(*) AS n_rows
FROM {{ model }}
WHERE {{ column_name }} IS NULL
   OR {{ column_name }} < 1
   OR {{ column_name }} > 5
GROUP BY 1

{% endtest %}
