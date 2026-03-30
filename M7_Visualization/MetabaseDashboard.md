# DASHBOARD en **Superset**

## Dashboard final debería tener:

### 📊 1. Distribución categórica

* Tickets por `priority`
* Tickets por `status`

### 📈 2. Serie temporal

* Tickets por día
* Tickets por semana

### 🔥 3. KPI PRO

* Avg resolution time
* Satisfaction score promedio
* SLA breaches


# COST OPTIMIZATION (clave en entrevistas)

* Parquet ✔
* Column pruning ✔
* Particionado por fecha ✔
* dbt incremental ✔

tests:

- dbt_utils.unique_combination_of_columns:
  combination_of_columns:
  - ticket_id
