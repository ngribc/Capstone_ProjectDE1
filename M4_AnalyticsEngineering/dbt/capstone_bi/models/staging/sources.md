version: 2
sources:
  - name: bronze
    schema: main
    description: "Tablas Bronze cargadas por Kestra"
    tables:
      - name: bronze_products
        columns:
          - name: id
            tests: [not_null]
          - name: snapshot_month
            tests: [not_null]
      - name: bronze_tickets
        columns:
          - name: snapshot_month
            tests: [not_null]
