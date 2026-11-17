USE nf3_lab;
-- Execute sem sessões concorrentes abertas nesta preparação.
START TRANSACTION;
UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=10 AND saldo>=1;
SELECT ROW_COUNT() linhas_alteradas;
SAVEPOINT depois_teclado;
UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=20 AND saldo>=1;
ROLLBACK TO SAVEPOINT depois_teclado;
SELECT rid,saldo FROM ESTOQUE WHERE rid IN (10,20) ORDER BY rid;
ROLLBACK;
-- Nada do experimento anterior foi confirmado.
START TRANSACTION;
INSERT INTO RESERVA(rid,qtd) VALUES (10,1);
UPDATE ESTOQUE SET saldo=saldo-1 WHERE rid=10 AND saldo>=1;
-- Exemplo controlado: saldo inicial conhecido >0. Em aplicação, conferir ROW_COUNT.
COMMIT;
SELECT * FROM RESERVA ORDER BY id;
