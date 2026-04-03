-- Test: El ROI nunca puede ser negativo. Si lo es, el pipeline debe alertar.
-- Efectiviza: Integridad de decisiones financieras.
SELECT * FROM {{ ref('fct_business_performance') }} WHERE roi_ratio < 0
