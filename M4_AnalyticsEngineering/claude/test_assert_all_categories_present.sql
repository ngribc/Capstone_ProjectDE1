-- tests/singular/assert_all_categories_present.sql
-- FakeStore has exactly 4 categories. This test fails if any is missing
-- from dim_category after a dbt run (catches data quality regressions).

SELECT
    expected_category,
    'missing from dim_category' AS reason
FROM (
    VALUES
        ('electronics'),
        ('jewelery'),
        ("men's clothing"),
        ("women's clothing")
) AS expected(expected_category)

LEFT JOIN {{ ref('dim_category') }} d
    ON d.category_name = expected_category

WHERE d.category_name IS NULL
