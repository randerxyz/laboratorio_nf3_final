import argparse
from conexao import conectar

p=argparse.ArgumentParser(description='Reserva atômica no estoque didático')
p.add_argument('rid',type=int)
p.add_argument('qtd',type=int)
a=p.parse_args()
if a.qtd<=0:
    p.error('Quantidade deve ser positiva')
db=conectar()
try:
    db.begin()
    with db.cursor() as c:
        c.execute('UPDATE nf3_lab.ESTOQUE SET saldo=saldo-%s WHERE rid=%s AND saldo>=%s',(a.qtd,a.rid,a.qtd))
        if c.rowcount!=1:
            raise ValueError('Produto inexistente ou saldo insuficiente')
        c.execute('INSERT INTO nf3_lab.RESERVA(rid,qtd) VALUES(%s,%s)',(a.rid,a.qtd))
        reserva=c.lastrowid
    db.commit()
    print({'reserva':reserva,'status':'confirmada'})
except Exception:
    db.rollback()
    raise
finally:
    db.close()
# TODO: classificar deadlock/timeout; retentar a transação inteira com limite.
# Repetir uma chamada confirmada ainda cria outra reserva: idempotência é extensão.
