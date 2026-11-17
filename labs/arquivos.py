import csv
from pathlib import Path
p=Path('evidencias');p.mkdir(exist_ok=True)
linhas=[{'pid':101,'cid':1,'nome':'Ana','cidade':'Catalao','rid':10},
        {'pid':101,'cid':1,'nome':'Ana','cidade':'Catalao','rid':20}]
linhas[0]['cidade']='Paracatu'  # atualização parcial: cliente agora tem duas cidades.
with (p/'vendas_redundantes.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=linhas[0].keys());w.writeheader();w.writerows(linhas)
for linha in linhas: print(linha)
# TODO: detectar inconsistência por cid. Um arquivo não fornece FK/ACID automaticamente.
