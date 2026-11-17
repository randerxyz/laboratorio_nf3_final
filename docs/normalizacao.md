# Oficina de modelagem e normalização

## Dependências da Loja Cerrado

Sob as regras dadas: cid → nome,cidade; pid → cid,status; rid → descricao,categoria;
(pid,rid) → qtd,preco; (cid,seq) → logradouro.
Não suponha nome → cid, cidade → nome ou rid → preco histórico.
O mesmo produto pode ser vendido por preços diferentes em pedidos diferentes.

1. Desenhe CLIENTE 1:N PEDIDO, PEDIDO N:N PRODUTO via ITEM e CLIENTE 1:N ENDERECO_ENTREGA.
2. Diferencie participação mínima e máxima: um cliente pode ter zero pedidos; cada pedido tem exatamente um cliente.
3. ITEM é associativa. ENDERECO_ENTREGA tem chave parcial seq e identificação dependente de cid.
4. PEDIDO continua entidade forte: possuir FK não o torna automaticamente entidade fraca.
5. CLIENTE_PF/PJ: as FKs não garantem totalidade/disjunção. Demonstre em transação e desfaça.
6. A Q08 da prova usa especialização SOBREPOSTA; a regra pretendida PF/PJ deste laboratório é DISJUNTA. A estrutura PK/FK permite ambas; a regra de negócio precisa ser aplicada.

## 1FN: atributos com múltiplos valores

VENDA_BRUTA(pid,cid,nome,cidade,produtos='10,20',quantidades='1,2').
Explique por que listas em campos dificultam integridade e consultas. Transforme em linhas de itens com valores atômicos para o domínio do exercício; apenas separar listas não resolve todas as dependências.

## 2FN: dependência parcial

MATRICULA(matricula_aluno,codigo_curso,nome_aluno,nome_curso,situacao).
Chave: (matricula_aluno,codigo_curso).
matricula_aluno → nome_aluno; codigo_curso → nome_curso;
(matricula_aluno,codigo_curso) → situacao.
Escreva DDL de ALUNO, CURSO e MATRICULA em nf3_lab; carregue dois alunos em dois cursos.
Preserve situacao na associação. Demonstre junção sem perda e manutenção de nomes sem repetição.

## 3FN: dependência transitiva

PEDIDO_REDUNDANTE(pid,cid,nome,cidade,status).
pid → cid,status; cid → nome,cidade.
Mesmo com PK simples, os dados de cliente devem ser separados: explique a dependência transitiva e as anomalias de atualização, inserção e exclusão.

## BCNF: caso que a 3FN não resolve

ALOCACAO(aluno,disciplina,professor).
Regras: (aluno,disciplina) → professor; professor → disciplina.
Um professor leciona somente uma disciplina; uma disciplina pode ter vários professores.
Chaves candidatas: (aluno,disciplina) e (aluno,professor).
Todos os atributos são primos, portanto a relação satisfaz 3FN para essas dependências.
professor não é superchave: professor → disciplina viola BCNF.

Tarefa: decomponha em PROFESSOR_DISCIPLINA(professor,disciplina) e ALUNO_PROFESSOR(aluno,professor).
A interseção professor determina a primeira relação: decomposição sem perda para instâncias válidas.
Mas (aluno,disciplina) → professor NÃO é preservada apenas pelas restrições locais:
se dois professores da mesma disciplina forem associados ao mesmo aluno, será necessária validação adicional.
Mostre esse contraexemplo com SQL. Não declare que toda decomposição BCNF preserva dependências.

## Critério de entrega

Para cada caso apresente chaves candidatas, dependências, forma normal violada, DDL proposto e consultas de reconstrução. Forma normal depende das dependências funcionais assumidas, não apenas de quantas tabelas foram criadas.
