# NF3 — Loja Cerrado: laboratório de Banco de Dados

**Criação e Estruturação de Banco de Dados por Consultas — UniAtenas — 2026/2**

Atividade para GitHub Codespaces, realizada por **linha de comando**: terminal Bash, cliente MySQL, scripts SQL e Python. Utilize o banco Loja Cerrado para explorar modelagem, consultas, administração, transações e diferentes modelos de persistência.

**Objetivo:** compreender projeto lógico/físico, consultas, processamento interno do SGBD, integridade, transações, administração e diferenças entre modelos de banco. O roteiro combina exemplos iniciais e tarefas a completar; não é apenas uma lista de comandos para copiar.

## 1. Preparação inicial no Codespaces

### 1.1 Repositório

Abra um Codespace deste repositório e utilize o terminal integrado. Se já estiver no ambiente, continue em “Inicializar ferramentas e banco”.

Para criar e acessar o ambiente pelo terminal do computador pessoal, utilize o GitHub CLI:

```bash
gh auth login
# Substitua pelo repositório real da turma.
gh codespace create -r ORGANIZACAO/REPOSITORIO -b main
gh codespace list
gh codespace ssh
```

Selecione o ambiente criado. Se já estiver dentro de um Codespace, utilize seu terminal. Os próximos comandos são executados **dentro do Codespace, na raiz do projeto**. A criação depende das permissões e disponibilidade da conta.

### 1.2 Inicializar ferramentas e banco

```bash
pwd
ls
python3 --version
docker version
docker compose version
bash scripts/preparar.sh
docker compose up -d --wait db
docker compose ps
```

A configuração do dev container inclui Docker-in-Docker. Se o daemon não responder, aguarde/conclua a preparação do ambiente e confira sua configuração. Se ela foi adicionada após a criação do Codespace, reconstrua o dev container.

O MySQL é acessível pelo terminal do Codespace em `127.0.0.1:3307`. A porta é diferente da usada normalmente por instalações locais e não deve ser encaminhada publicamente. As senhas são fictícias, visíveis no projeto e exclusivas deste laboratório privado.

```bash
bash scripts/mysql.sh < sql/01_inspecao.sql
```

Contagens iniciais: CLIENTE=5, PEDIDO=5, PRODUTO=5, ITEM=9, CLIENTE_PF=4, CLIENTE_PJ=1, ENDERECO_ENTREGA=3. O script também mostra PKs, FKs, CHECKs, engine e isolamento.

### 1.3 Preparar Python

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
set -a
source .env
set +a
mkdir -p evidencias
python -m pip freeze > evidencias/dependencias.txt
```

Repita a ativação do ambiente e o carregamento de `.env` em novos terminais. Não publique `.env`. Os exemplos Python usam a conta `aluno_nf3`; o script MySQL administrativo usa root do contêiner para DDL e investigação. Diferencie essas funções.

### 1.4 Organização

| Local | Conteúdo |
|---|---|
| `dados/01_loja_cerrado.sql` | Esquema e registros originais; contém DROP DATABASE |
| `dados/02_laboratorio.sql` | Base separada `nf3_lab`, estoque fictício, auditoria, reservas e contas |
| `sql/01` a `sql/09` | Inspeção, DDL/DML, consultas, complementos, views/triggers, transações, índices, motor e modelos |
| `scripts/` | Cliente MySQL, SQL via Python, reserva transacional, backup e restauração |
| `labs/` | Arquivo redundante, distribuição simulada e persistência de objetos |
| `docs/normalizacao.md` | Casos de 1FN, 2FN, 3FN e BCNF |
| `docs/concorrencia.md` | Ordem exata dos comandos em duas sessões |
| `docs/relatorio.md` | Registro dos experimentos |

Os scripts de `dados/` rodam automaticamente apenas quando o volume MySQL está vazio. Reiniciar o contêiner não reaplica esses arquivos. As demais práticas são executadas manualmente, na ordem do roteiro.

### 1.5 SGBD, arquivos e arquitetura

```bash
python labs/arquivos.py
bash scripts/mysql.sh -e 'SELECT VERSION(),@@default_storage_engine;'
```

O CSV gerado repete dados de Ana e atualiza sua cidade em apenas uma linha. Identifique a inconsistência. Um formato CSV não fornece, por si só, FK, transação, controle de concorrência e recuperação; aplicações podem implementar controles, mas precisam assumir esse trabalho.

Descreva o caminho: cliente/driver → autenticação → análise da consulta → otimização → execução → buffer pool/páginas → log e arquivos. O otimizador escolhe estratégias; o buffer pool mantém páginas em memória; log e recuperação dão suporte à restauração transacional. Não confunda buffer pool com cache HTTP ou com o resultado completo de cada SELECT.

**Tarefa:** compare MySQL/InnoDB, PostgreSQL e SQLite por arquitetura, concorrência, administração e cenário de uso. SQLite é um SGBD relacional embutido, não um simples CSV. Consultar documentação oficial e registrar versão quando discutir comportamento específico.

## 2. Modelo relacional, chaves, cardinalidades e especialização

Na Loja Cerrado:

- CLIENTE tem PK `cid`; PEDIDO tem PK `pid` e FK `cid`.
- Um cliente pode ter zero ou vários pedidos; cada pedido referencia exatamente um cliente.
- PEDIDO e PRODUTO têm relacionamento N:N representado por ITEM.
- ITEM tem PK composta `(pid,rid)`; quantidade e preço pertencem à participação do produto naquele pedido.
- ENDERECO_ENTREGA tem PK `(cid,seq)`; `seq` identifica o endereço apenas dentro de um cliente. É o exemplo de entidade fraca.
- PEDIDO possui identidade própria: ter FK não o torna, automaticamente, entidade fraca.
- CLIENTE_PF e CLIENTE_PJ compartilham a identidade do supertipo por PK/FK.

Abra o cliente interativo:

```bash
bash scripts/mysql.sh --interativo loja_cerrado
```

Execute os experimentos **um comando por vez**, porque alguns erros são intencionais:

```sql
-- FK inexistente: falha, não cria cliente automaticamente.
START TRANSACTION;
INSERT INTO PEDIDO(pid,cid,status) VALUES(9901,450,'PENDENTE');
ROLLBACK;

-- Vários pedidos podem referenciar o mesmo cid: FK não é UNIQUE.
START TRANSACTION;
INSERT INTO PEDIDO(pid,cid,status) VALUES(9902,1,'PENDENTE'),(9903,1,'PENDENTE');
SELECT pid,cid FROM PEDIDO WHERE cid=1 ORDER BY pid;
ROLLBACK;

-- Chave composta: seq pode repetir para outro cliente.
SELECT cid,seq,logradouro FROM ENDERECO_ENTREGA ORDER BY cid,seq;
START TRANSACTION;
INSERT INTO ENDERECO_ENTREGA VALUES(1,1,'Endereco duplicado');
ROLLBACK;

-- Domínios e CHECKs.
START TRANSACTION;
INSERT INTO ITEM VALUES(101,50,0,450.00);
ROLLBACK;

-- FK não garante disjunção entre PF e PJ.
START TRANSACTION;
INSERT INTO CLIENTE_PJ VALUES(1,'90000000000001','Contato de teste');
SELECT f.cid FROM CLIENTE_PF f JOIN CLIENTE_PJ j ON j.cid=f.cid;
ROLLBACK;

-- FK também não garante totalidade dos subtipos.
START TRANSACTION;
INSERT INTO CLIENTE VALUES(99,'Sem subtipo','Catalao');
SELECT * FROM CLIENTE WHERE cid=99;
ROLLBACK;
exit
```

**Tarefa:** desenhe o esquema lógico, com PK/FK, cardinalidades e participação. Proponha uma estratégia transacional para validar totalidade/disjunção; discuta concorrência e como impedir que duas sessões criem subtipos incompatíveis. FKs preservam existência do supertipo, não a regra “um ou outro”. Explique também por que pedido CONCLUIDO com ao menos um item exige validação além da FK ITEM→PEDIDO.

## 3. Normalização: 1FN, 2FN, 3FN e BCNF

Leia `docs/normalizacao.md` e resolva os quatro casos. Crie as tabelas próprias em `nf3_lab`, usando prefixo `EX_` para não colidir com as demais práticas.

| Forma | O que justificar | Exercício |
|---|---|---|
| 1FN | Valores atômicos no domínio e ausência de grupos repetitivos | Venda com listas de produtos/quantidades |
| 2FN | Dependência completa de cada atributo não primo em relação às chaves candidatas | MATRÍCULA com chave aluno/curso e nomes dependentes de partes |
| 3FN | Para cada DF não trivial X→A, X é superchave ou A é atributo primo | Pedido com dados repetidos de cliente |
| BCNF | Todo determinante de DF não trivial é superchave | Alocação aluno/disciplina/professor |

Uma PK composta não garante 3FN. PK simples também não elimina dependências transitivas. A análise deve considerar todas as chaves candidatas e dependências relevantes.

**Registre em `docs/relatorio.md`:** dependências funcionais, chaves candidatas, anomalias, DDL de decomposição e consultas de reconstrução. No caso BCNF, explique por que a decomposição pode ser sem perda e ainda não preservar todas as dependências por restrições locais.

No projeto físico, justifique `DECIMAL(10,2)` para preço, tipos inteiros para chaves, `NOT NULL`, charset/collation e InnoDB. Comprimentos, collation e índices afetam armazenamento e comparação; escolhas físicas não substituem o modelo lógico.

## 4. DDL, DML, filtros e ordenação

```bash
bash scripts/mysql.sh < sql/02_ddl_dml.sql
```

O script cria uma tabela temporária no sentido didático (`PRODUTO_EXERCICIO`, uma tabela comum), insere produtos, altera um preço, exclui uma linha, acrescenta coluna e remove a tabela ao final. Identifique a categoria de cada comando:

- DDL: CREATE, ALTER, DROP; define estrutura.
- DML: INSERT, UPDATE, DELETE; modifica registros.
- DQL: SELECT; rótulo didático para consulta, também incluído em DML em algumas classificações.

A tabela original PRODUTO não possui preço ou estoque. Para consultar produtos por preço e disponibilidade, a base `nf3_lab` contém ESTOQUE com preço corrente e saldo fictícios. Com os dados iniciais, `preco > 500 AND saldo > 0` retorna somente **Monitor**. Cadeira tem preço 600, mas saldo zero.

**Tarefas:**

1. Compare AND com OR e explique as linhas adicionais.
2. Escreva um UPDATE precedido de SELECT com o mesmo WHERE e confira `ROW_COUNT()` imediatamente depois do UPDATE.
3. Diferencie apagar registros (`DELETE`), esvaziar tabela (`TRUNCATE`) e remover estrutura (`DROP`). TRUNCATE não aceita WHERE.
4. Compare filtro por igualdade, IN, BETWEEN, LIKE e IS NULL. `= NULL` não substitui IS NULL.
5. Paginação: use `ORDER BY cidade,cid` antes de LIMIT/OFFSET para garantir desempate estável.

**Cuidado transacional:** muitos comandos DDL no MySQL provocam commit implícito. Não use `START TRANSACTION; DROP TABLE ...; ROLLBACK;` esperando recuperar a tabela. Os exercícios destrutivos ficam em tabelas específicas da base didática.

## 5. JOINs, GROUP BY/HAVING e subconsultas

```bash
bash scripts/mysql.sh < sql/03_consultas.sql
```

Resultados de referência com a carga original:

| Consulta | Resultado esperado |
|---|---|
| Clientes de Catalao | Ana, Carla e Eva |
| INNER JOIN cliente/pedido | 5 linhas; Ana aparece em dois pedidos |
| Todos os clientes + pedidos concluídos, filtro no ON | Ana/101, Bruno/103, Carla/104, Diego/NULL, Eva/NULL |
| Mesmo filtro no WHERE | Apenas Ana/101, Bruno/103 e Carla/104 |
| Cliente sem qualquer pedido | Eva |
| Pedidos concluídos com total > 500 | 104 = 1.130,00; 103 = 980,00 |
| Total dos concluídos | 3 pedidos; 7 linhas de itens; 2.420,00 |
| Ticket médio dos concluídos | 806,67 |

A consulta com RIGHT JOIN do script troca os lados das tabelas para preservar CLIENTE. Trocar apenas LEFT por RIGHT mantendo a ordem das tabelas não preserva necessariamente o mesmo conjunto.

**Tarefas:**

1. Acrescente total zero para cliente sem pedido concluído.
2. Encontre produtos nunca vendidos em pedido concluído e diferencie de produtos nunca presentes em qualquer ITEM.
3. Compare EXISTS e IN; escreva NOT EXISTS para clientes sem pedidos. Explique o problema de NOT IN quando a subconsulta pode retornar NULL.
4. Compare WHERE (filtra linhas antes de agrupar) com HAVING (filtra grupos).
5. Calcule ticket médio após totalizar por pedido: AVG do valor da linha de item não é ticket médio do pedido.
6. Escreva uma subconsulta correlacionada para clientes que têm ao menos um pedido concluído.
7. Represente em álgebra relacional seleção, projeção, junção e diferença em duas consultas. SQL pode preservar duplicatas; projeção da álgebra clássica tem semântica de conjuntos.

## 6. Recursos complementares e SQL na aplicação

```bash
bash scripts/mysql.sh < sql/04_complementos.sql
python scripts/sql_python.py --cidade Catalao
python scripts/sql_python.py --cidade "' OR 1=1 -- "
```

O primeiro Python retorna Ana, Carla e Eva. O segundo trata a entrada inteira como valor de cidade, sem transformá-la em código SQL. O exemplo usa parâmetros `%s` do driver, nunca f-string para montar valores.

O script SQL demonstra CTE, função de janela, CASE, COALESCE, UNION e UNION ALL. Explique a diferença entre agrupar linhas e calcular uma janela preservando as linhas.

**SQL embutida/incorporada:** aqui a aplicação Python incorpora comandos SQL por API/driver. A expressão “SQL embutida” também pode designar a forma clássica com `EXEC SQL` e pré-compilador em linguagens como C; esse mecanismo clássico não é executado no pacote.

**Tarefas:** acrescente filtro opcional e paginação ao Python, mantendo parâmetros para valores. Se permitir coluna de ordenação, use lista permitida: placeholders de valores não representam nomes de tabelas ou colunas.

Exemplo inicial de rotina armazenada, para executar no cliente administrativo `nf3_lab`:

```sql
DROP PROCEDURE IF EXISTS listar_saldo;
DELIMITER $$
CREATE PROCEDURE listar_saldo(IN minimo INT)
BEGIN
 SELECT rid,descricao,saldo FROM ESTOQUE WHERE saldo>=minimo ORDER BY rid;
END$$
DELIMITER ;
CALL listar_saldo(5);
```

Explique procedimento × consulta enviada por driver e por que DELIMITER é comando do cliente para interpretar o script, não parte da sintaxe SQL enviada ao servidor como instrução comum.

## 7. Views, triggers e privilégios

```bash
bash scripts/mysql.sh < sql/05_views_triggers.sql
```

A view está em `nf3_lab`, mas consulta dados originais de `loja_cerrado`. Ela retorna pid, cid e total, sem CPF ou endereço. Uma view comum armazena a definição da consulta, não uma cópia materializada atualizada automaticamente.

O trigger AFTER UPDATE registra mudança de saldo com OLD e NEW. A auditoria usa InnoDB, portanto participa da transação: ao fazer ROLLBACK, atualização e registro de auditoria são desfeitos. Lacunas no AUTO_INCREMENT não indicam, sozinhas, corrupção.

**Tarefas:**

1. Faça UPDATE+COMMIT e compare com UPDATE+ROLLBACK.
2. Explique CHECK × trigger × validação da aplicação. Não implemente regra declarativa simples com trigger sem necessidade.
3. Explique por que trigger de auditoria transacional não registra de forma durável uma tentativa que foi desfeita.
4. A view usa SQL SECURITY DEFINER: os privilégios do definidor autorizam o acesso subjacente. Em produção, substitua o definidor root por uma conta dedicada de menor privilégio; diferencie DEFINER e INVOKER.

Teste a conta restrita:

```bash
docker compose exec -T db sh -c \
 'MYSQL_PWD=leitor_local mysql -uleitor_nf3 -e "SELECT * FROM loja_cerrado.PRODUTO; SELECT * FROM nf3_lab.V_VENDAS_CONCLUIDAS;"'
docker compose exec -T db sh -c \
 'MYSQL_PWD=leitor_local mysql -uleitor_nf3 -e "SELECT cpf FROM loja_cerrado.CLIENTE_PF;"'
```

O segundo comando deve ser negado. Não confunda autenticar com autorizar. A conta `aluno_nf3` é mais ampla para estudo; não é o exemplo de acesso restrito a documentos.

```bash
bash scripts/mysql.sh -e "SHOW GRANTS FOR 'leitor_nf3'@'%';"
bash scripts/mysql.sh -e "REVOKE SELECT ON nf3_lab.V_VENDAS_CONCLUIDAS FROM 'leitor_nf3'@'%';"
# Repita a consulta à view e observe a negativa. Depois recoloque:
bash scripts/mysql.sh -e "GRANT SELECT ON nf3_lab.V_VENDAS_CONCLUIDAS TO 'leitor_nf3'@'%';"
```

Registre privilégios mínimos para relatório, operação de estoque e administração. Proponha rotação de credenciais, proteção de conexão, segregação e revisão periódica. Não coloque senhas reais em repositório.

## 8. ACID e controle de concorrência

```bash
bash scripts/mysql.sh < sql/06_transacoes.sql
python scripts/reservar.py 10 1
```

O primeiro script demonstra SAVEPOINT, ROLLBACK parcial, ROLLBACK total e COMMIT; a parte final confirma uma reserva didática. O Python fornece a versão com verificação de saldo e tratamento de exceção: UPDATE condicional, checagem de rowcount, INSERT e COMMIT; em falha, ROLLBACK.

| Propriedade | O que explicar com a reserva |
|---|---|
| Atomicidade | Atualizar saldo e registrar reserva como uma unidade |
| Consistência | Preservar regras declaradas e de negócio; ACID não cria regras ausentes |
| Isolamento | Interferência de operações concorrentes depende do nível e dos locks |
| Durabilidade | Commit confirmado deve sobreviver conforme garantias/configuração do mecanismo e armazenamento |

O script de reserva não tem idempotência: repetir uma chamada concluída cria outra reserva. Isso é uma extensão de aplicação, distinta da atomicidade da transação.

Abra `docs/concorrencia.md`. Ele traz a ordem dos comandos para:

1. Leitura suja com READ UNCOMMITTED e comparação com READ COMMITTED.
2. Leitura não repetível e comparação com REPEATABLE READ.
3. Fantasma em READ COMMITTED e snapshot consistente em REPEATABLE READ.
4. Atualização perdida por cálculo obsoleto na aplicação.
5. SELECT FOR UPDATE, espera e liberação de lock.
6. Deadlock, vítima escolhida pelo SGBD e ordem consistente de aquisição.
7. Discussão de starvation e MVCC.

**Importante:** cada terminal mantém uma conexão MySQL aberta. Executar START TRANSACTION em um comando separado de shell e UPDATE em outro abre conexões diferentes e destrói a experiência pretendida.

Não execute todos os comandos de A primeiro e depois todos os de B. Siga a sequência intercalada. Faça COMMIT/ROLLBACK antes de sair ou mudar de cenário.

**Registro do experimento:** preencha a tabela de `docs/relatorio.md` com estado inicial, sequência A/B, valores observados, anomalia, correção e limitações. Diferencie dirty read, non-repeatable read, phantom, lost update, deadlock e starvation.

## 9. Índices, plano físico e funcionamento interno

A carga original é pequena: uma varredura completa pode ser a melhor escolha. Por isso a prática gera **100.000 pedidos sintéticos em nf3_lab.PEDIDO_MASSA**, sem alterar PEDIDO original.

```bash
bash scripts/mysql.sh < sql/07_preparar_indices.sql | tee evidencias/indices.txt
bash scripts/mysql.sh < sql/08_motor.sql > evidencias/motor.txt
```

O primeiro script pode levar tempo conforme os recursos. Ele cria massa, atualiza estatísticas, mostra EXPLAIN ANALYZE antes/depois de um índice composto `(cid,status,criado_em,id)` e lista índices.

**Tarefas:**

- Compare acesso, linhas estimadas/reais, ordenação e tempo; não invente percentual de ganho.
- Explique seletividade, ordem das colunas e prefixo à esquerda. Um índice não melhora toda consulta.
- Discuta custo de escrita, armazenamento e manutenção de índices.
- Compare `WHERE criado_em >= '2026-06-01' AND criado_em < '2026-07-01'` com aplicação de função sobre a coluna. Avalie o plano com índice adequado à data; o índice inicial começa por cid e não substitui qualquer índice de data.
- Repita consultas quentes e frias de maneira honesta. Não alegue cache frio só porque abriu outro cliente; o buffer pool pertence ao servidor.

`EXPLAIN` descreve o plano; `EXPLAIN ANALYZE` executa a consulta e acrescenta medições. Neste roteiro são SELECTs. Os contadores globais do servidor podem incluir trabalho de outras sessões.

### Redo, undo, WAL, buffer pool e binlog

Explique a sequência conceitual: transação modifica páginas em memória; informações de recuperação são registradas; a política de commit define sincronização do log; páginas sujas podem ser gravadas depois. WAL exige persistência do log necessário antes da página correspondente. Não significa gravar toda página alterada no disco em cada commit.

- **Redo:** permite refazer alterações necessárias na recuperação.
- **Undo:** suporta desfazimento e versões anteriores usadas no MVCC.
- **Buffer pool:** páginas de dados/índices em memória; pode conter páginas sujas.
- **Binlog:** eventos usados, entre outras funções, em replicação e recuperação até um ponto no tempo; não é o mesmo log físico de redo.
- **Checkpoint:** relaciona o avanço de páginas persistidas e o trabalho de recuperação; não é simplesmente COMMIT de todas as transações.

O script mostra parâmetros e estado; disponibilidade de binlogs/diagnósticos depende da configuração e privilégios. Uma reinicialização limpa não simula queda de energia; não declare crash recovery validada só por reiniciar o contêiner. Descreva também shadow paging como estratégia alternativa conceitual, sem atribuí-la ao mecanismo padrão do InnoDB.

## 10. Backup, recuperação e continuidade

```bash
bash scripts/backup.sh
ARQUIVO=$(cat backups/ultimo.txt)
bash scripts/restaurar.sh "$ARQUIVO" | tee evidencias/restauracao.txt
```

O backup cobre **loja_cerrado**, a base original. O dump não inclui CREATE DATABASE/USE e a restauração usa uma base nova, cujo nome é exibido. O script de restauração não apaga a base de origem.

Na carga original, a base restaurada deve conter 5 clientes, 9 itens e soma geral `SUM(qtd*preco)=4220,00` incluindo todos os estados. Esse total difere do faturamento elegível de pedidos concluídos (2420,00).

**Tarefas:**

1. Compare contagens e linhas por chave nas duas bases; checksum do arquivo verifica integridade do arquivo, não equivalência semântica completa da base.
2. Faça um backup, acrescente um registro de teste à origem em transação confirmada, restaure o backup antigo e demonstre a ausência da alteração na cópia. Remova depois o registro de teste de forma controlada.
3. Defina metas de RPO e RTO para o cenário do laboratório e diferencie perda temporal tolerada de prazo para recuperação. O tempo SQL mostrado não inclui detecção, validação e retorno da aplicação.
4. Proponha backup externo/isolado, controle de acesso, criptografia e retenção. `backups/` no mesmo Codespace não protege contra perda do ambiente.
5. Planeje recuperação point-in-time: backup base consistente + sequência de binlogs com posição/GTID correspondente e retenção suficiente. O dump fornecido não configura sozinho PITR.
6. Amplie o procedimento para `nf3_lab` se precisar preservar os experimentos. A view dessa base referencia loja_cerrado e tem definidor: não basta renomear o esquema do dump e presumir isolamento. Liste dependências, rotinas, triggers, contas e privilégios que precisariam ser tratados.

`--single-transaction` fornece snapshot consistente para tabelas transacionais como InnoDB sob as condições apropriadas; evite DDL concorrente durante o dump. Dump de dados não substitui exportação de contas/GRANTs ou teste de restauração.

## 11. Projeto físico e administração integrada

Consolide as decisões em `docs/relatorio.md`:

1. Esquema lógico da loja, dependências e regras não cobertas pelas constraints atuais.
2. Tipos, charset/collation, mecanismos de integridade e plano de índices.
3. Consultas frequentes e planos observados, justificando escolhas físicas.
4. Matriz de permissões e interfaces de acesso por driver/view.
5. Estratégia de concorrência para estoque, tratamento de falhas e procedimentos de recuperação.

**Desafio integrador:** finalize um pedido em uma única transação somente se houver ao menos um item. Não altere o domínio de status para nomes incompatíveis. Discuta como impedir alterações concorrentes que removam os itens durante a validação; apenas verificar COUNT em uma aplicação sem coordenação não garante a regra. Registre o código e descreva os locks e a ordem de acesso utilizados.

## 12. Bancos distribuídos e modelos não convencionais

### 12.1 Particionamento horizontal e réplica assíncrona

```bash
python labs/distribuido.py
```

O script usa `cid % 2` como função determinística de distribuição e gera arquivos de primário/réplica para cada partição. Altera um primário e mostra uma leitura desatualizada na réplica até você pressionar ENTER para propagar.

**É uma simulação em arquivos locais, não uma implantação distribuída real.** Não mede rede, consenso, failover ou transações distribuídas. Observe a distribuição dos registros e o atraso de propagação entre as cópias.

**Tarefas:**

- Explique particionamento (subconjuntos diferentes) × replicação (cópias do mesmo subconjunto).
- Mostre onde consultar cid=1 e cid=2. Como obter total global de vendas?
- Proponha co-localizar pedidos e itens com seu cliente; discuta produtos compartilhados.
- Simule partição indisponível e marque explicitamente resposta parcial, sem apresentá-la como resultado global completo.
- Explique leitura após escrita em réplica assíncrona, atraso e roteamento ao primário.
- Discuta transação que envolve duas partições: atomicidade local não garante atomicidade global; 2PC e compensações têm custos e garantias diferentes.
- Diferencie particionamento interno de tabela em um único servidor de sharding entre servidores. O primeiro não torna automaticamente o banco distribuído.

### 12.2 Banco orientado a objetos de verdade

```bash
python labs/objetos.py
python labs/objetos.py
```

O exemplo usa **ZODB**, um banco de objetos, e cria um cliente PJ e dois pedidos que referenciam o mesmo objeto. A segunda execução abre o armazenamento persistido. Observe classe, identificador persistente, referência compartilhada e rollback de alteração não confirmada.

As classes ficam em `labs/objetos_modelo.py`, um módulo importável, e não apenas no escopo efêmero da aplicação. Os IDs 901/902 são exemplos independentes no banco de objetos; não são inseridos no MySQL.

**Tarefas:** acrescente atributo e comprove persistência com commit entre execuções; compare identidade de objeto com igualdade de atributos; explique referências e herança. Usar classes Python, ORM ou serializar JSON não transforma, por si só, um banco relacional em banco orientado a objetos. Neste exemplo, o FileStorage local não é uma implantação distribuída e deve ser aberto por um processo por vez.

### 12.3 Documentos JSON e relações de grafo

```bash
bash scripts/mysql.sh < sql/09_json_grafos.sql
```

A prática usa campo JSON e travessia de arestas por CTE recursiva. São demonstrações de representação e consulta dentro do MySQL, não uma alegação de que ele se tornou um banco documental ou de grafos nativo. O grafo inicial é acíclico; se adicionar ciclos, implemente prevenção de revisitas, não apenas limite de profundidade.

**Tarefa:** modele um catálogo com atributos variáveis como documento e uma rede de recomendações como grafo. Compare com tabelas relacionais, considerando consultas, integridade, redundância e evolução.

### 12.4 Chave-valor com Redis

Esta prática usa um serviço adicional, iniciado somente pelo perfil `modelos`:

```bash
docker compose --profile modelos up -d redis
docker compose exec -T redis redis-cli SET produto:10:saldo 10
docker compose exec -T redis redis-cli GET produto:10:saldo
docker compose exec -T redis redis-cli DECRBY produto:10:saldo 2
docker compose exec -T redis redis-cli SET sessao:ficticia ativo EX 60
docker compose exec -T redis redis-cli TTL sessao:ficticia
```

Não há porta pública do Redis. AOF foi habilitado no contêiner, mas isso não elimina a necessidade de discutir política de persistência e backup. A chave é didática e não atualiza ESTOQUE do MySQL; não mantenha dois saldos como fontes concorrentes de verdade sem estratégia de consistência.

### Comparação final

| Modelo | Unidade/estrutura principal | Ponto de análise |
|---|---|---|
| Relacional | Relações, chaves, constraints e operações relacionais | Como manter integridade e consultar junções? |
| Orientado a objetos | Identidade persistente, objetos e referências | Como preservar identidade e hierarquias? |
| Documental | Documentos agregados com atributos variáveis | O que embutir e o que referenciar? |
| Chave-valor | Chave e valor associado | Como acessar por chave e controlar expiração? |
| Grafo | Vértices, arestas e propriedades | Como realizar travessias de relacionamentos? |
| Distribuído | Organização dos dados/serviços em múltiplos nós | Como particionar, replicar e coordenar? |

“Distribuído” não é uma alternativa mutuamente exclusiva a relacional ou documental: diversos modelos podem ser distribuídos. Evite afirmar que NoSQL significa ausência de transações ou ausência de qualquer esquema.

## 13. Registro dos experimentos

Use `docs/relatorio.md` como caderno do laboratório. Ao concluir cada etapa, registre:

- Comando ou script executado, versão do ambiente e resultado observado.
- Esquema lógico, chaves e dependências dos casos de normalização.
- Consultas produzidas e interpretação dos resultados.
- Planos de execução antes e depois dos índices.
- Comportamento de views, triggers e permissões.
- Sequência das sessões A/B, valores lidos e alterações confirmadas ou desfeitas.
- Procedimento de restauração e comparação entre origem e cópia.
- Diferenças observadas entre persistência relacional, objetos, documentos e chave-valor.

Salve saídas textuais em `evidencias/`. Revise os arquivos antes de compartilhá-los e remova credenciais. A pasta é ignorada pelo Git por padrão; mantenha apenas os registros necessários para reproduzir e compreender os experimentos.

## 14. Encerramento e solução de problemas

```bash
# Para o banco, preservando o volume:
docker compose --profile modelos down
# Retomar:
docker compose up -d --wait db
```

No terminal pessoal, `gh codespace stop` encerra o uso do ambiente selecionado. Não exclua o Codespace antes de guardar os resultados necessários.

**Reset destrutivo:** `docker compose --profile modelos down -v` remove os volumes MySQL/Redis deste projeto. Na próxima inicialização, a carga será recriada. Use somente se decidir descartar os experimentos. O arquivo SQL original contém DROP DATABASE e também apaga a base se executado manualmente.

| Problema | Verificação |
|---|---|
| Erro ao conectar MySQL | `docker compose ps` e `docker compose logs --tail=80 db` |
| Porta 3307 ocupada | Ajustar mapeamento e DB_PORT em conjunto |
| Alterou dados/*.sql, mas nada mudou | Init não é reexecutado em volume existente; aplicar migração |
| ImportError no Python | Ativar .venv e instalar requirements |
| Access denied no Python | Carregar .env; verificar GRANTs da conta utilizada |
| FOREIGN KEY/CHECK rejeita operação | Verificar regra e valores; não desativar integridade para “corrigir” |
| Sessão aparentemente travada | Investigar locks; encerrar transação da outra sessão corretamente |
| Table exists ao repetir exercício próprio | Criar estratégia de reset apenas das tabelas do exercício |
| Erro esperado interrompe arquivo SQL | Fazer o experimento interativo, uma instrução por vez |

## 15. Referências oficiais

- MySQL 8.4: https://dev.mysql.com/doc/refman/8.4/en/
- Isolamento InnoDB: https://dev.mysql.com/doc/refman/8.4/en/innodb-transaction-isolation-levels.html
- Commits implícitos: https://dev.mysql.com/doc/refman/8.4/en/implicit-commit.html
- Leituras bloqueantes: https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html
- ZODB: https://zodb.org/en/latest/introduction.html
- Objetos persistentes: https://zodb.org/en/latest/guide/writing-persistent-objects.html
- Codespaces pelo CLI: https://docs.github.com/pt/codespaces/developing-in-a-codespace/using-github-codespaces-with-github-cli
- Docker Compose: https://docs.docker.com/compose/

As imagens e dependências precisam ser baixadas no Codespace. Registre as versões efetivamente instaladas; os intervalos de dependência do ZODB permitem atualizações dentro da versão principal indicada.
