Servidor principal de Spark
El servidor principal de Spark es el que levantará, entre otras cosas, la interfaz gráfica. Por defecto, la levantará en el puerto 8080 del equipo anfitrión aunque este puerto puede ser sobreescrito mediante la variable de entorno SPARK_MASTER_UI_PORT. Este servicio abrirá también el puerto 7077 para comunicarse con trabajadores Spark, siendo este puerto sobreescribirble mediante la variable de entorno SPARK_MASTER_PORT.

La variable SPARK_NO_DAEMONIZE=true hace que el script de inicio mantenga el proceso en primer plano (comportamiento necesario en Docker).

spark-master:
  image: apache/spark:3.5.8-scala2.12-java17-python3-ubuntu
  container_name: spark-master
  hostname: spark-master
  environment:
    - SPARK_NO_DAEMONIZE=true
  ports:
    - "${SPARK_MASTER_UI_PORT:-8080}:8080"
    - "${SPARK_MASTER_PORT:-7077}:7077"
  command: /opt/spark/sbin/start-master.sh
  volumes:
    - ./notebooks:/workspace
Trabajador de Spark
El trabajador de Socker no requiere ninguna configuración y está preconfigurado para que se comunique con el servicio principal de Spark.

spark-worker:
  image: apache/spark:3.5.8-scala2.12-java17-python3-ubuntu
  container_name: spark-worker
  depends_on:
    - spark-master
  environment:
    - SPARK_NO_DAEMONIZE=true
  command: /opt/spark/sbin/start-worker.sh spark://spark-master:7077
  volumes:
    - ./notebooks:/workspace
Servidor de cuadernos de Jupyter
El servidor de cuadernos Jupyter está disponible por defecto en el puerto 8888 del equipo anfitrión, siendo el puerto modificable mediante la variable de entorno JUPYTER_PORT. Gracias a que usa nuestra imagen personalizada (basada en la oficial de Spark), tiene disponibles pyspark, pandas y pyarrow entre otras utilidades.

La variable de entorno SPARK_MASTER es leída explícitamente en el cuaderno para conectarse al cluster: os.environ.get('SPARK_MASTER', 'local[*]').

jupyter:
  build: .
  container_name: spark-jupyter
  depends_on:
    - spark-master
  environment:
    - SPARK_MASTER=spark://spark-master:7077
  ports:
    - "${JUPYTER_PORT:-8888}:8888"
  command: >
    jupyter notebook
    --ip=0.0.0.0
    --allow-root
    --no-browser
    --NotebookApp.token=''
  volumes:
    - ./notebooks:/workspace
