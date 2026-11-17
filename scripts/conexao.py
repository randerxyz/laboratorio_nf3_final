import os
import pymysql

def conectar():
    return pymysql.connect(host=os.getenv('DB_HOST','127.0.0.1'),port=int(os.getenv('DB_PORT','3307')),
        user=os.getenv('DB_USER','aluno_nf3'),password=os.getenv('DB_PASSWORD','aluno_local'),
        database=os.getenv('DB_NAME','loja_cerrado'),autocommit=False,charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor,connect_timeout=5)
