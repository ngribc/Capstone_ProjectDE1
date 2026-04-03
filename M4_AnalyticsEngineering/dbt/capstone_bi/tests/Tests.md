# Dos causas de errores en datos #
# 1 Datos fuente incorrectos o mal documentados.
# 2 Errores en SQL: joins mal hechos, bugs, edge cases no contemplados.

#El rol del ingeniero de datos es identificar cuál de las dos causas aplica.

# Singular Test #
# Devuelven error si existe al menos una fila que cumple una condición no deseada.
# Ejemplo: validar que cada camión tenga datos completos de 24 horas.
select
    order_id,
    sum(amount) as total_amount
from {{ef('fct_payments')}}
group by all
having sum(amount) < 0

# Source freshness tests #
version:2

sources:
    -name: jaffle_shop
    database: raw
    freshness # default freshness
        warn_after: {count: 12, period: hour}
        error_after: {count: 24, period:hour}
    loaded_at_field: -_etl_loaded_at

    tables:
        - name: orders
        freshness: # make this a little more strict
            warn_after: {count: 6, period: hour}
            error_after: {count: 12, period: hour}

        - name: product_skus
            freshness: null # do not check freshness for this tables

# Configurados en archivos YAML.
# Verifican que los datos estén actualizados según un campo de carga.
# Útiles para monitorear la frescura de las fuentes.
# dbt source freshness

# Generic tests #
Cuatro pruebas incluidas en dbt: unique, not_null, accepted_values, relationships.
Se definen en YAML y permiten validar integridad referencial y reglas básicas.

version: 2
models:
    - name: orders
      columns:
          - name: order_id
            tests:
                - unique
                - not_null
            - name: status
            tests:
            - accepted_values: 
                values: ['placed', 'shipped', 'completed', 'returned']
            - name: customer_id
            tests:
            - relationships:
                to: ref('customers')
                field: customer_id

# Custom generic tests #
# Posibilidad de escribir tests propios en SQL/Jinja.
# Se usan para reglas específicas de negocio (ej. impuestos únicos según características de vehículos).
Se ponen de esta forma: /tests/.sql
# { % test warn_if_odd(model, column_name) % } #
    {{ config(severity='warn') }}
    select *
    from {{model}}
    where ({{column_name}} % 2) = 1
{ % endtest % }

# Unit tests #
#Introducidos en dbt 1.8.
#Permiten definir fixtures: entradas y salidas esperadas para validar lógica compleja (ej. regex, ventanas móviles).
#Ayudan a prevenir errores antes de que aparezcan en datos reales.
with customers as ( 
    select * from {{ ref ('stg_customers')}}
),

check_valid_emails as (
    select
        regexp_like(
            email,
            '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            ) as is_valid_email_adrress
        from customers
)

select * from check_valid_emails

unit_test:
- name: test_is_valid_email_address
    description: "Check my is_valid_email_address logic captures all known edge cases."
    model: my_model
    given:
        - input: ref('stg_customers')
        rows:
        - {email: cool@example.com}
        - {email: cool@unkown.com}
        - {email: badgmail.com}
        - {email: missing@gmail.com}
    expect:
    rows:
        - {email: cool@example.com, is_valid_email_address: true}
        - {email: coll@unkown.com, is_valid_email_address: false}
        - {email: badgmail.com, is_valid_email_address: false}
        - {email: missingdot@gmail.com, is_valid_email_address: false}

# Model contracts #
#Configuración en YAML para forzar tipos de datos, nombres de columnas y restricciones.
#Si el modelo no cumple el contrato, falla la construcción.
Basado en el concepto de data contracts negociados con stakeholders.
models:
    - name: dim_customers
    config:
        constract:
            enforced: true
    columns:
        - name: customer_id
            data_type: int
            constraints:
                - type: not_null
            - name: customer_name
                data_type: string
            ...
######
Los tests en dbt permiten detectar errores a tiempo y entender sus causas.
Son esenciales en entornos de datos maduros para garantizar confiabilidad.
######