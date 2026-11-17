import json
from pathlib import Path

# Simulação explícita: arquivos locais NÃO são servidores distribuídos reais.
# hash determinístico didático = cid % 2.
pasta=Path('evidencias/distribuido'); pasta.mkdir(parents=True,exist_ok=True)
clientes=[{'cid':1,'nome':'Ana','cidade':'Catalao'},{'cid':2,'nome':'Bruno','cidade':'Paracatu'},
 {'cid':3,'nome':'Carla','cidade':'Catalao'},{'cid':4,'nome':'Diego','cidade':'Goiania'},
 {'cid':5,'nome':'Eva','cidade':'Catalao'}]
shards={i:[c.copy() for c in clientes if c['cid']%2==i] for i in (0,1)}
for i,linhas in shards.items():
    (pasta/f'primario_{i}.json').write_text(json.dumps(linhas,indent=2))
    (pasta/f'replica_{i}.json').write_text(json.dumps(linhas,indent=2))
shards[1][0]['cidade']='Cidade corrigida'
(pasta/'primario_1.json').write_text(json.dumps(shards[1],indent=2))
print('Primario:',json.loads((pasta/'primario_1.json').read_text())[0])
print('Replica antes da propagacao:',json.loads((pasta/'replica_1.json').read_text())[0])
input('Pressione ENTER para propagar a escrita para a replica...')
(pasta/'replica_1.json').write_text((pasta/'primario_1.json').read_text())
print('Replica depois:',json.loads((pasta/'replica_1.json').read_text())[0])
print('Global ordenado:',sorted([c for s in shards.values() for c in s],key=lambda c:c['cid']))
# TODO: simular partição indisponível e resposta parcial sinalizada.
