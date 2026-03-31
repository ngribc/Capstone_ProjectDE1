-- tests/generic/positive_value.sql
-- Generic test: asserts that a column has only positive values (> 0).
-- Usage in schema.yml:
--   - positive_value
--
-- Returns rows that FAIL the test (dbt fails if any rows returned).

{% test positive_value(model, column_name) %}

SELECT
    {{ column_name }} AS failing_value,
    COUNT(*) AS n_rows
FROM {{ model }}
WHERE {{ column_name }} IS NULL
   OR {{ column_name }} <= 0
GROUP BY 1

{% endtest %}
