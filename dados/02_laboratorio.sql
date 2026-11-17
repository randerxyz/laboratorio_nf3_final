-- Extensões ficam fora da base original.
CREATE DATABASE nf3_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nf3_lab;
CREATE TABLE ESTOQUE (
 rid INT PRIMARY KEY, descricao VARCHAR(100) NOT NULL,
 preco DECIMAL(10,2) NOT NULL CHECK(preco>=0),
 saldo INT NOT NULL CHECK(saldo>=0)
) ENGINE=InnoDB;
INSERT INTO ESTOQUE VALUES
 (10,'Teclado',150,10),(20,'Mouse',80,20),(30,'Cadeira',600,0),(40,'Monitor',900,5),(50,'Mesa',450,3);
CREATE TABLE AUDITORIA_ESTOQUE (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, rid INT NOT NULL,
 antes INT NOT NULL, depois INT NOT NULL,
 conta VARCHAR(288) NOT NULL, instante DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB;
CREATE TABLE RESERVA (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, rid INT NOT NULL, qtd INT NOT NULL CHECK(qtd>0),
 criada_em DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY(rid) REFERENCES ESTOQUE(rid)
) ENGINE=InnoDB;
CREATE TABLE DOCUMENTO (
 id INT PRIMARY KEY, dados JSON NOT NULL
) ENGINE=InnoDB;
CREATE TABLE ARESTA (
 origem INT NOT NULL, destino INT NOT NULL, PRIMARY KEY(origem,destino)
) ENGINE=InnoDB;
INSERT INTO ARESTA VALUES (1,2),(2,3),(1,4),(4,5);
CREATE USER 'aluno_nf3'@'%' IDENTIFIED BY 'aluno_local';
CREATE USER 'leitor_nf3'@'%' IDENTIFIED BY 'leitor_local';
GRANT SELECT ON loja_cerrado.* TO 'aluno_nf3'@'%';
GRANT SELECT,INSERT,UPDATE,DELETE ON nf3_lab.* TO 'aluno_nf3'@'%';
GRANT SELECT ON loja_cerrado.PRODUTO TO 'leitor_nf3'@'%';
-- Usuário da aplicação sem DDL, GRANT ou leitura de documentos pessoais desnecessários.
-- aluno_nf3 é conta didática de leitura ampla da base original; leitor_nf3 é restrita.
