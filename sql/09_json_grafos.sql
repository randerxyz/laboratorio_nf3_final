USE nf3_lab;
INSERT INTO DOCUMENTO(id,dados) VALUES (1,JSON_OBJECT('cid',1,'nome','Ana','preferencias',JSON_ARRAY('Informatica','Moveis')))
 ON DUPLICATE KEY UPDATE dados=JSON_OBJECT('cid',1,'nome','Ana','preferencias',JSON_ARRAY('Informatica','Moveis'));
SELECT id,JSON_UNQUOTE(JSON_EXTRACT(dados,'$.nome')) nome FROM DOCUMENTO;
UPDATE DOCUMENTO SET dados=JSON_SET(dados,'$.cidade','Catalao') WHERE id=1;
SELECT dados FROM DOCUMENTO WHERE id=1;
-- Travessia em DAG de exemplo; limite de profundidade evita expansão ilimitada.
WITH RECURSIVE caminhos AS (
 SELECT origem,destino,1 profundidade FROM ARESTA WHERE origem=1
 UNION ALL
 SELECT c.origem,a.destino,c.profundidade+1 FROM caminhos c JOIN ARESTA a ON a.origem=c.destino
 WHERE c.profundidade<5
) SELECT * FROM caminhos ORDER BY profundidade,destino;
-- Tabela JSON não torna MySQL um banco documental puro; CTE não o torna banco de grafos.
