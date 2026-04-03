## Highlights
0:03 Introducción a los dbt packages

Los paquetes son proyectos independientes con macros, tests y modelos.

Se pueden compartir y usar como librerías.

1:00 dbt-utils: el paquete más popular

Incluye funciones SQL comunes como pivot, deduplicate, safe divide.

Compatible con distintos warehouses (BigQuery, DuckDB, etc.).

3:07 Otros paquetes destacados

Project Evaluator: evalúa tu proyecto y da un puntaje de buenas prácticas.

Codegen: genera automáticamente archivos YAML y SQL, ahorrando tiempo.

Audit Helper: compara modelos antiguos y nuevos para validar refactorización.

5:00 Paquetes específicos por warehouse

Ejemplo: Snowflake, con macros para monitoreo de costos y buenas prácticas.

6:00 dbt-expectations: tests preconstruidos

Incluye pruebas listas para usar (row count, regex, casing, valores nulos).

Reduce la necesidad de escribir tests SQL personalizados.

7:01 Cómo instalar un paquete

Crear archivo packages.yml.

Añadir el nombre y versión del paquete.

Ejecutar dbt deps para instalar dependencias.

8:29 Ejemplo práctico con dbt-utils

Uso de macros para generar claves únicas (surrogate keys).

Garantiza compatibilidad entre distintos dialectos SQL.

En conclusión, el video muestra cómo los dbt packages permiten extender proyectos, ahorrar tiempo y aplicar buenas prácticas sin reinventar la rueda.

¿Quieres que te arme una tabla comparativa con los paquetes más útiles (dbt-utils, Codegen, Audit Helper, dbt-expectations) y sus principales ventajas?