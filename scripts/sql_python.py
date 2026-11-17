import argparse
from conexao import conectar

p=argparse.ArgumentParser(description='SQL parametrizado em Python: filtro por cidade')
p.add_argument('--cidade',default='Catalao')
a=p.parse_args()
db=conectar()
try:
    with db.cursor() as c:
        c.execute('SELECT cid,nome,cidade FROM CLIENTE WHERE cidade=%s ORDER BY cid',(a.cidade,))
        for linha in c.fetchall():
            print(linha)
finally:
    db.close()
# TODO: adicionar paginação com limites e seleção de ORDER BY por lista permitida.
# É SQL incorporado via driver, não a sintaxe de pré-compilador EXEC SQL.
