from pathlib import Path
import transaction
from ZODB import DB
from ZODB.FileStorage import FileStorage
from objetos_modelo import ClientePJ,Pedido

Path('objetos').mkdir(exist_ok=True)
armazenamento=FileStorage('objetos/loja.fs')
banco=DB(armazenamento)
con=banco.open()
try:
    raiz=con.root()
    if 'cliente' not in raiz:
        raiz.cliente=ClientePJ(5,'Eva','Contato ficticio')
        raiz.pedido_a=Pedido(901,raiz.cliente)
        raiz.pedido_b=Pedido(902,raiz.cliente)
        transaction.commit()
    print('Classe:',type(raiz.cliente).__name__)
    print('Identidade persistente:',raiz.cliente._p_oid.hex())
    print('Referencia compartilhada:',raiz.pedido_a.cliente is raiz.pedido_b.cliente)
    nome=raiz.cliente.nome
    raiz.cliente.nome='Alteracao nao confirmada'
    transaction.abort()
    print('Abort restaurou nome:',raiz.cliente.nome==nome)
finally:
    con.close()
    banco.close()
# Execute duas vezes: persistência entre processos, herança e referência compartilhada.
