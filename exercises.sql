CREATE DATABASE ecommerce;

CREATE ROLE admin WITH LOGIN PASSWORD 'training';
CREATE ROLE customer WITH LOGIN PASSWORD 'training';
CREATE ROLE vendor WITH LOGIN PASSWORD 'training';

GRANT CREATE ON DATABASE ecommerce TO admin;

-- Pour les tables existantes
GRANT SELECT ON ALL TABLES IN SCHEMA public TO customer;

-- Dans le cas d'un schéma particulier

GRANT USAGE ON SCHEMA inventory TO customer;
GRANT SELECT ON ALL TABLES IN SCHEMA inventory TO customer;


-- Pour les tables futures
ALTER DEFAULT PRIVILEGES IN SCHEMA inventory GRANT SELECT ON TABLES TO customer;

-- Pour les tables existantes
GRANT SELECT, INSERT ON produits TO vendor;
GRANT SELECT, INSERT ON inventaire TO vendor;

-- Pour les tables futures (si vous prévoyez de créer d'autres tables similaires)
ALTER DEFAULT PRIVILEGES IN SCHEMA inventory GRANT SELECT, INSERT ON TABLES TO vendor;

REVOKE CONNECT ON DATABASE ecommerce FROM customer;

CREATE ROLE general_user WITH LOGIN PASSWORD 'training';

GRANT customer TO general_user;
GRANT vendor TO general_user;

-- Accorder l'accès à la base de données à admin et general_user
GRANT CONNECT ON DATABASE ecommerce TO admin;
GRANT CONNECT ON DATABASE ecommerce TO general_user;

-- Révoquer l'accès pour tous les autres rôles, si nécessaire
REVOKE CONNECT ON DATABASE ecommerce FROM PUBLIC;

ALTER ROLE admin WITH CONNECTION LIMIT 5;

------------------------------------------

CREATE TABLE author (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    birthdate DATE,
    UNIQUE (first_name, last_name)
);

CREATE TABLE book (
    id SERIAL PRIMARY KEY,
    title VARCHAR(32) NOT NULL,
    published_date DATE DEFAULT CURRENT_DATE,
    genre VARCHAR(32) DEFAULT 'Inconnu',
    author_id INT REFERENCES author(id)
);

ALTER TABLE book
ADD CONSTRAINT fk_author
FOREIGN KEY (author_id)
REFERENCES author(id);

ALTER TABLE book
ADD CONSTRAINT check_published_date
CHECK (published_date <= CURRENT_DATE);

ALTER TABLE book
ADD CONSTRAINT unique_title
UNIQUE (title);

ALTER TABLE author
ADD COLUMN nationality CHAR(2);

ALTER TABLE book
ADD COLUMN ISBN CHAR(32) UNIQUE;

CREATE TABLE book_copy (
    book_id INT,
    copy_number INT,
    PRIMARY KEY (book_id, copy_number),
    FOREIGN KEY (book_id) REFERENCES book(id)
);

CREATE TYPE book_status AS ENUM ('available', 'borrowed', 'maintenance');

ALTER TABLE book_copy
ADD COLUMN status book_status DEFAULT 'available';

ALTER TABLE book
ADD COLUMN keywords VARCHAR(32)[];

-- Remplacement de la contrainte existante afin d'ajouter le cascading

ALTER TABLE book
DROP CONSTRAINT fk_author;

ALTER TABLE book
ADD CONSTRAINT fk_author
FOREIGN KEY (author_id)
REFERENCES author(id)
ON DELETE CASCADE;

CREATE TYPE author AS ENUM ('first', 'second');


CREATE TABLE book_author (
    book_id INT,
    author_id INT,
    role author,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE CASCADE
);

-----------------------------------------------------

SELECT first_name, last_name FROM author;

SELECT title FROM book;

SELECT first_name, last_name FROM author WHERE first_name = 'John';

SELECT first_name, last_name FROM author WHERE first_name LIKE 'J%'; -- vs ILIKE

SELECT b.title, a.first_name, a.last_name
FROM book b
JOIN book_author ba ON b.id = ba.book_id
JOIN author a ON ba.author_id = a.id;

SELECT b.title
FROM book b
JOIN book_author ba ON b.id = ba.book_id
JOIN author a ON ba.author_id = a.id
WHERE a.first_name = 'Jane' AND a.last_name = 'Austen';

SELECT a.first_name, a.last_name
FROM author a
JOIN book_author ba ON a.id = ba.author_id
GROUP BY a.id
HAVING COUNT(ba.book_id) > 3;

SELECT COUNT(*) FROM book;

SELECT a.first_name, a.last_name, count(ba.book_id) as num
FROM author a
JOIN book_author ba ON a.id = ba.author_id
GROUP BY a.id
ORDER BY COUNT(ba.book_id) DESC
LIMIT 3;

SELECT AVG(book_count) AS average_books
FROM (
    SELECT COUNT(ba.book_id) AS book_count
    FROM author a
    JOIN book_author ba ON a.id = ba.author_id
    GROUP BY a.id
) AS author_book_counts;

SELECT a.first_name, a.last_name
FROM author a
LEFT JOIN book_author ba ON a.id = ba.author_id
WHERE ba.book_id IS NULL;

SELECT b.title
FROM book b
JOIN book_author ba ON b.id = ba.book_id
JOIN author a ON ba.author_id = a.id
WHERE a.last_name = 'Verne';

SELECT a.first_name, a.last_name, COUNT(ba.book_id)
FROM author a
JOIN book_author ba ON a.id = ba.author_id
GROUP BY a.id
HAVING COUNT(ba.book_id) = (
    SELECT COUNT(ba2.book_id)
    FROM author a2
    JOIN book_author ba2 ON a2.id = ba2.author_id
    WHERE a2.first_name = 'Victor' AND a2.last_name = 'Hugo'
);

CREATE TABLE editor (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birthdate DATE
);

INSERT INTO editor (first_name, last_name, birthdate) VALUES ('Charles', 'Dickens', '1812-02-07');
INSERT INTO editor (first_name, last_name, birthdate) VALUES ('Jane', 'Austen', '1775-12-16');
INSERT INTO editor (first_name, last_name, birthdate) VALUES ('Marcel', 'Proust', '1871-07-10');

SELECT a.first_name, a.last_name
FROM author a
JOIN editor e ON a.first_name = e.first_name AND a.last_name = e.last_name;

SELECT a.first_name, a.last_name
FROM author a
LEFT JOIN editor e ON a.first_name = e.first_name AND a.last_name = e.last_name
WHERE e.first_name IS NULL;

SELECT first_name, last_name FROM author
UNION
SELECT first_name, last_name FROM editor;

-----------------------------------------------

-- Scénario 1 - GIN: Les recherches textuelles partielles, surtout sur des colonnes contenant des valeurs textuelles longues, 
-- bénéficient de l'utilisation d'un index GIN. Cet index est efficace pour les opérations de recherche de texte intégral 
-- et les correspondances partielles.

-- L'extension pg_trgm doit être activée pour utiliser gin_trgm_ops, qui est idéale pour les recherches de similarité 
-- et les correspondances partielles.

CREATE INDEX idx_delivery_address_gin ON orders USING gin (delivery_address gin_trgm_ops);

-- Scénario 2 - B-TREE: Les index B-tree sont bien adaptés pour les requêtes de plage et les recherches exactes sur des colonnes de type date. 
-- Ils permettent un accès rapide aux données triées par date.

CREATE INDEX idx_order_date ON orders(order_date);

-- corrélation élevée avec l'ordre physique des lignes
-- Consomme beaucoup moins d'espace disque qu'un index B-tree
CREATE INDEX idx_order_date_brin ON orders USING brin(order_date);

-- Scénario 3 - B-TREE: Bien que la colonne order_status ait une faible cardinalité (peu de valeurs distinctes), un index B-tree est généralement efficace 
-- pour les filtres sur des colonnes avec des valeurs discrètes. Cela est particulièrement vrai si les requêtes filtrent souvent par statut.

CREATE INDEX idx_order_status ON orders(order_status);

-- Scénario 4 - B-TREE: Un index composite sur customer_id et product_id est idéal pour optimiser les requêtes qui filtrent sur la combinaison 
-- de ces deux colonnes. Cela permet de réduire le nombre de lectures nécessaires pour accéder aux données pertinentes.

CREATE INDEX idx_customer_product ON orders(customer_id, product_id);