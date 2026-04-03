-- Alerta si el tiempo de resolución promedio supera las 48hs (Problema de Negocio)
SELECT * FROM {{ ref('fct_business_performance') }} 
WHERE avg_resolution_time > 48
