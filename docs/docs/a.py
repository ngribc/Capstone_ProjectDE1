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
