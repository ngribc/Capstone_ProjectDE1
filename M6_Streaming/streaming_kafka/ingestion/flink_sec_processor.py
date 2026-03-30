import hashlib

def salted_hash_pii(email):
    # EL HUMANO define el Salt para máxima seguridad
    SALT = "BUSSINESS_PROD_SECRET_2026"
    return hashlib.sha256((email + SALT).encode()).hexdigest()

# Lógica PyFlink para transformar 'raw_tickets' -> 'clean_tickets'
# 1. Filtra PII (Email)
# 2. Valida Contrato de Datos (Data Drift)

# ingestion/flink_processor.py (Fragmento)
def mask_email(email):
    salt = "SECRET_KEY_123"
    return hashlib.sha256((email + salt).encode()).hexdigest()

# PyFlink aplica esto a cada evento de Kafka
t_env.create_temporary_system_function("mask_email", mask_email)
