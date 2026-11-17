# Concorrência: execução manual em duas sessões

Abra dois terminais do Codespace. Em CADA um:

```bash
bash scripts/mysql.sh --interativo nf3_lab
```

Identifique como A e B. Não cole a tabela inteira de uma vez: execute **uma linha por etapa** na sessão indicada. `START TRANSACTION` e os demais comandos precisam ocorrer na mesma conexão. O script não automatiza a ordem nem os tempos.

Antes de cada cenário: `ROLLBACK;` nas duas sessões; em A, execute `SET autocommit=1; UPDATE ESTOQUE SET saldo=10 WHERE rid IN (10,20);`. Isso altera apenas o estoque didático. Não reinicie saldos enquanto houver transações abertas.

## 1. Leitura suja — Q07

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `START TRANSACTION;` | |
| 2 | `UPDATE ESTOQUE SET saldo=99 WHERE rid=10;` | |
| 3 | | `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` |
| 4 | | `START TRANSACTION; SELECT saldo FROM ESTOQUE WHERE rid=10;` |
| 5 | `ROLLBACK;` | |
| 6 | | `SELECT saldo FROM ESTOQUE WHERE rid=10; COMMIT;` |

B pode ver 99 antes de A confirmar e 10 após rollback. Repita com READ COMMITTED: B deve ler 10 mesmo enquanto A mantém a alteração não confirmada. Não use SELECT FOR UPDATE neste cenário: é outro tipo de leitura.

## 2. Leitura não repetível

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED; START TRANSACTION; SELECT saldo FROM ESTOQUE WHERE rid=10;` | |
| 2 | | `START TRANSACTION; UPDATE ESTOQUE SET saldo=15 WHERE rid=10; COMMIT;` |
| 3 | `SELECT saldo FROM ESTOQUE WHERE rid=10; COMMIT;` | |

A lê 10 e depois 15. Repita a preparação e use REPEATABLE READ em A: SELECTs consistentes comuns usam o snapshot estabelecido pela primeira leitura. Não generalize esse resultado a leituras bloqueantes/UPDATE, que têm semântica diferente.

## 3. Fantasma

Remova eventual linha do experimento anterior: `DELETE FROM ESTOQUE WHERE rid=99;` com autocommit, sem transações abertas.

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED; START TRANSACTION; SELECT rid FROM ESTOQUE WHERE preco>500 ORDER BY rid;` | |
| 2 | | `INSERT INTO ESTOQUE VALUES(99,'Extra',700,1); COMMIT;` |
| 3 | `SELECT rid FROM ESTOQUE WHERE preco>500 ORDER BY rid; COMMIT;` | |

Surge uma linha no conjunto. Repita com REPEATABLE READ em A depois de remover 99: SELECT consistente comum mantém o snapshot. Em leituras de intervalo com FOR UPDATE, índices e next-key locks podem bloquear inserções; é um experimento adicional, não o mesmo mecanismo do snapshot.

## 4. Atualização perdida por cálculo obsoleto na aplicação

Reinicie saldo de rid=10 em 10. Use READ COMMITTED e autocommit=1 em ambas.

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `SELECT saldo FROM ESTOQUE WHERE rid=10;` | |
| 2 | | `SELECT saldo FROM ESTOQUE WHERE rid=10;` |
| 3 | `UPDATE ESTOQUE SET saldo=9 WHERE rid=10;` | |
| 4 | | `UPDATE ESTOQUE SET saldo=9 WHERE rid=10;` |

Duas vendas calculadas sobre saldo 10 resultam em 9, não 8. O problema é gravar um valor calculado com leitura antiga. Compare com duas execuções de `UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=10 AND saldo>=1; SELECT ROW_COUNT();`: o cálculo é feito pelo banco com controle de concorrência.

## 5. Bloqueio pessimista e leitura atual

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `START TRANSACTION; SELECT saldo FROM ESTOQUE WHERE rid=10 FOR UPDATE;` | |
| 2 | | `SET SESSION innodb_lock_wait_timeout=20; START TRANSACTION; UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=10 AND saldo>=1;` |
| 3 | `UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=10 AND saldo>=1; COMMIT;` | aguardando |
| 4 | | comando retorna; `SELECT ROW_COUNT(); COMMIT;` |

Execute o passo 3 antes de 20 segundos para observar liberação normal. Se houver timeout, faça ROLLBACK em B e repita: timeout de statement não implica sempre rollback da transação inteira.

Em um terceiro terminal, enquanto B espera: `bash scripts/mysql.sh < sql/08_motor.sql`. Procure o lock e a espera no performance_schema.

## 6. Deadlock com ordem inversa

| Passo | Sessão A | Sessão B |
|---|---|---|
| 1 | `START TRANSACTION; UPDATE ESTOQUE SET saldo=saldo+1 WHERE rid=10;` | |
| 2 | | `START TRANSACTION; UPDATE ESTOQUE SET saldo=saldo+1 WHERE rid=20;` |
| 3 | `UPDATE ESTOQUE SET saldo=saldo+1 WHERE rid=20;` (aguarda) | |
| 4 | | `UPDATE ESTOQUE SET saldo=saldo+1 WHERE rid=10;` |
| 5 | confirme ou desfaça a sobrevivente | uma sessão recebe erro de deadlock |

Não presuma qual será a vítima. Registre o erro, encerre ambas com ROLLBACK e consulte SHOW ENGINE INNODB STATUS. Corrija adquirindo locks na mesma ordem (rid crescente), reduzindo duração e prevendo retry limitado da transação inteira.

## 7. Starvation e MVCC

Starvation é adiamento repetido de uma transação; não precisa existir ciclo de espera. Faça uma linha do tempo hipotética e proponha métricas/limites de espera. Este roteiro não promete reproduzi-la deterministicamente no escalonador do InnoDB.

Explique MVCC com versões e visibilidade de snapshots: leitura consistente pode usar versões anteriores sem esperar por um escritor; isso não significa que todo SELECT seja livre de bloqueios ou que todo isolamento seja serializável.

Ao finalizar cada experiência: COMMIT ou ROLLBACK, depois `exit`. Nunca deixe terminal com transação aberta durante o intervalo.
