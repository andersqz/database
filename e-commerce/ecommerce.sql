
USE ecommerce;

-- 2. Tabela de categorias (Evitar repetir nomes de categorias nos produtos)
CREATE TABLE IF NOT EXISTS categorias (
    id_categoria INT PRIMARY KEY DEFAULT AUTOINCREMENT,
    nome_categoria VARCHAR(100) NOT NULL,
    descricao_categoria TEXT
);


-- 3. Tabela de clientes
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT PRIMARY KEY DEFAULT AUTOINCREMENT,
    nome_cliente VARCHAR(100) NOT NULL,
    email_cliente VARCHAR(100) UNIQUE NOT NULL,
    cpf_cliente CHAR(11) UNIQUE NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabela de produtos (FK para categorias)
CREATE TABLE IF NOT EXISTS produtos (
    id_produto INT PRIMARY KEY DEFAULT AUTOINCREMENT,
    id_categoria INT,
    preco_produto DECIMAL(10, 2) NOT NULL,
    estoque_produto INT DEFAULT 0,
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

ALTER TABLE produtos
ADD nome_produto VARCHAR(150) NOT NULL;


-- 5. Tabela de pedidos (FK para clientes)
CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT PRIMARY KEY DEFAULT AUTOINCREMENT,
    id_cliente INT,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) 
    CHECK (status IN ('Pendente', 'Pago', 'Enviado', 'Cancelado')) DEFAULT 'Pendente',
    total_pedido DECIMAL(10, 2),
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

select * from pedidos


-- 6. Tabela de Itens do Pedido (tabela de relacionamento N:N entre pedidos e produtos)
-- Essa tabela é essencial para a normalização, permitindo que um pedido tenha vários produtos.
CREATE TABLE IF NOT EXISTS itens_pedidos (
    id_item INT PRIMARY KEY DEFAULT AUTOINCREMENT,
    id_pedido INT,
    id_produto INT,
    quantidade_item INT NOT NULL,
    preco_unitario_item DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_item_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    CONSTRAINT fk_item_produto FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);


-- A. Cadastrando Categorias e Clientes (As bases)
INSERT INTO categorias (nome_categoria, descricao_categoria)
    VALUES ('Eletrônicos', 'Produtos de tecnologia e hardware'),
           ('Livros', 'Livros físicos e digitais'),
           ('Perfumaria', 'Produtos de auto-cuidado e perfumes'); 

SELECT * FROM categorias

INSERT INTO clientes (nome_cliente, email_cliente, cpf_cliente)
    VALUES ('Ana Souza', 'ana.souza@email.com', '12345678922'),
           ('Carlos Lima', 'carlos.lima@email.com', '98765432100'),
            ('Silvio Santos', 'silvio.santos@email.com', '45698732100');

SELECT * FROM clientes


-- B. Cadastrando Produtos (Referenciando o ID da categoria)
-- Supondo que 'Eletrônicos' seja ID 1, 'Livros' seja ID 2, e 'Perfumaria' seja ID 3
INSERT INTO produtos (id_categoria, nome_produto, preco_produto, estoque_produto)
    VALUES (1, 'Smartphone X', 2500.00, 50),
           (1, 'PlayStation 5', 3999.00, 10),
           (2, 'David Copperfield', 42.50, 100),
           (2, 'Entendendo Algoritmos', 54.99, 100),
           (3, 'Perfume Malbec 100ml', 120.99, 20),
           (3, 'Creme Nivea', 12.99, 200);

SELECT * FROM produtos


-- C. Criando um pedido (Referenciando o ID do cliente)
INSERT INTO pedidos (id_cliente, status, total_pedido)
    VALUES (1, 'Pendente', 2542.00)

SELECT * FROM pedidos

-- D. Adicionando itens ao pedido (Referenciando pedido e produto)
-- Aqui o aluno vê a normalização na prática: o item liga o pedido ao produtos
INSERT INTO itens_pedidos (id_pedido, id_produto, quantidade_item, preco_unitario_item)
    VALUES (1, 1, 1, 2500.00), -- 1 SMARTPHONE
           (1, 2, 1, 3999.00), -- 2 playstation
           (1, 3, 1, 42.50); -- 3 Livro

select * from itens_pedidos

-- em sequencia
-- DROP TABLE itens_pedidos;
-- DROP TABLE pedidos;
-- DROP TABLE produtos;
-- DROP TABLE clientes;

UPDATE pedidos  
SET status = 'Pago'
WHERE id_pedido = 1;

SELECT * FROM pedidos

UPDATE clientes
SET email_cliente = 'ana.nova@email.com'
WHERE id_cliente = 1;

SELECT * FROM clientes

SELECT nome_produto, preco_produto FROM produtos
WHERE preco_produto > 100.00 ORDER BY preco_produto desc;

------------------------------------------------------------

-- Produtos com categorias
SELECT p.nome_produto   AS Produto,
       c.nome_categoria AS Categoria,
       p.preco_produto  AS Preco
FROM   produtos   p
INNER JOIN categorias c
       ON p.id_categoria = c.id_categoria


-- Total gasto por cliente
SELECT cl.nome_cliente              AS Cliente,
       SUM(p.total_pedido)           AS total_gasto
FROM   clientes cl
LEFT JOIN pedidos p
       ON cl.id_cliente = p.id_cliente
GROUP BY cl.id_cliente, cl.nome_cliente



-- itens de pedidos pagos
SELECT c.nome_cliente         AS Cliente,
       pr.nome_produto        AS Produto,
       ip.quantidade_item     AS Quantidade,
       ped.data_pedido        AS Data
FROM   itens_pedidos ip
JOIN   pedidos       ped ON ip.id_pedido  = ped.id_pedido
JOIN   clientes       c   ON ped.id_cliente = c.id_cliente
JOIN   produtos        pr  ON ip.id_produto  = pr.id_produto
WHERE  ped.status = 'Pago'


-- Produtos com mais de 5 itens vendidos
WITH resumo_vendas AS (
    SELECT
        id_produto,
        SUM(quantidade_item)                        AS total_unidades,
        SUM(quantidade_item * preco_unitario_item)  AS receita_produto
    FROM   itens_pedidos
    GROUP BY id_produto
)
SELECT
    p.nome_produto      AS Produto,
    rv.total_unidades,
    rv.receita_produto
FROM   produtos      p
JOIN   resumo_vendas rv ON p.id_produto = rv.id_produto
WHERE  rv.total_unidades > 5
