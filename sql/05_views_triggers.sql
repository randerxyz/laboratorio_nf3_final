USE nf3_lab;
CREATE OR REPLACE SQL SECURITY DEFINER VIEW V_VENDAS_CONCLUIDAS AS
 SELECT p.pid,p.cid,SUM(i.qtd*i.preco) total
 FROM loja_cerrado.PEDIDO p JOIN loja_cerrado.ITEM i ON i.pid=p.pid
 WHERE p.status='CONCLUIDO' GROUP BY p.pid,p.cid;
-- Somente resultado agregado, sem documentos pessoais.
GRANT SELECT ON nf3_lab.V_VENDAS_CONCLUIDAS TO 'leitor_nf3'@'%';
DROP TRIGGER IF EXISTS tr_estoque_auditoria;
DELIMITER $$
CREATE TRIGGER tr_estoque_auditoria AFTER UPDATE ON ESTOQUE FOR EACH ROW
BEGIN
 IF OLD.saldo<>NEW.saldo THEN
  INSERT INTO AUDITORIA_ESTOQUE(rid,antes,depois,conta)
  VALUES (NEW.rid,OLD.saldo,NEW.saldo,USER());
 END IF;
END$$
DELIMITER ;
START TRANSACTION;
UPDATE ESTOQUE SET saldo=saldo+1 WHERE rid=10;
SELECT * FROM AUDITORIA_ESTOQUE ORDER BY id DESC LIMIT 3;
ROLLBACK;
-- A auditoria é transacional e a linha acima é desfeita; ID pode ficar com lacuna.
SELECT * FROM V_VENDAS_CONCLUIDAS ORDER BY pid;
