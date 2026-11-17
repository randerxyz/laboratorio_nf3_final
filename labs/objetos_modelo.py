from persistent import Persistent

class Cliente(Persistent):
    def __init__(self,cid,nome):
        self.cid=cid
        self.nome=nome

class ClientePJ(Cliente):
    def __init__(self,cid,nome,contato):
        super().__init__(cid,nome)
        self.contato=contato

class Pedido(Persistent):
    def __init__(self,pid,cliente):
        self.pid=pid
        self.cliente=cliente
