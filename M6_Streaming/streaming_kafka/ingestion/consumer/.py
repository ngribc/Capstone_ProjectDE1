# Usa una versión real y estable (ej: 1.20)
FROM flink:1.20.0-scala_2.12-java17

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Instala la versión de PyFlink que coincida con la imagen base
RUN UV_BREAK_SYSTEM_PACKAGES=1 uv pip install --system apache-flink==1.20.0

# Directorio estándar para conectores
WORKDIR /opt/flink/lib

# Descarga conectores que coincidan con la versión 1.20
RUN curl -O https://maven.org \
    && curl -O https://maven.org \
    && curl -O https://postgresql.org

# Cambiar permisos para que el usuario 'flink' pueda leerlos
RUN chown -R flink:flink /opt/flink/lib/

USER flink
