select name,
	case
		when height < 150 then 'cat 1'
		when height between 150 and 170 then 'cat 2'
		when height between 170 and 190 then 'cat 3'
		else 'cat 4'
	end as category
from people;

--------------------------------------------------------------

-- Customer Table
CREATE TABLE Customer (
    id INT PRIMARY KEY,                      -- PRIMARY KEY Constraint
    first_name VARCHAR(50) NOT NULL,         -- NOT NULL Constraint
    last_name VARCHAR(50) NOT NULL,          -- NOT NULL Constraint
    email VARCHAR(100) UNIQUE,               -- UNIQUE Constraint
    phone_number VARCHAR(15) CHECK (LENGTH(phone_number) >= 10),  -- CHECK Constraint for phone number length
    birth_date DATE DEFAULT CURRENT_DATE     -- DEFAULT Constraint (assuming today's date if not provided)
);

-- Account Table
CREATE TABLE Account (
    id INT PRIMARY KEY,                      -- PRIMARY KEY Constraint
    customer_id INT,
    balance DECIMAL(15, 2) CHECK (balance >= 0),  -- CHECK Constraint to ensure balance is non-negative
    account_type VARCHAR(50) NOT NULL,
    openedOn DATE DEFAULT CURRENT_DATE,      -- DEFAULT Constraint
    FOREIGN KEY (customer_id) REFERENCES Customer(id)  -- FOREIGN KEY Constraint
);

--------------------------------------------

CREATE TABLE Customer (
    id INT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone_number VARCHAR(15),
    birth_date DATE DEFAULT CURRENT_DATE,
    CONSTRAINT pk_customer PRIMARY KEY (id),
    CONSTRAINT nn_first_name NOT NULL (first_name),
    CONSTRAINT nn_last_name NOT NULL (last_name),
    CONSTRAINT uq_email UNIQUE (email),
    CONSTRAINT chk_phone_number CHECK (LENGTH(phone_number) >= 10)
);

CREATE TABLE Account (
    id INT,
    customer_id INT,
    balance DECIMAL(15, 2),
    account_type VARCHAR(50) NOT NULL,
    openedOn DATE DEFAULT CURRENT_DATE,
    CONSTRAINT pk_account PRIMARY KEY (id),
    CONSTRAINT chk_balance CHECK (balance >= 0),
    CONSTRAINT nn_account_type NOT NULL (account_type),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customer(id)
);

CREATE VIEW CustomerAccountSummary AS
SELECT 
    c.first_name,
    c.last_name,
    c.email,
    a.account_type,
    a.balance
FROM 
    Customer c
JOIN 
    Account a ON c.id = a.customer_id;

-----------------------------------------------

-- Sous-requête

SELECT 
    c.description AS category_name,
    (SELECT COUNT(*) 
     FROM inventory.products p 
     WHERE p.category_id = c.id) AS product_count
FROM 
    inventory.categories c
WHERE 
    (SELECT COUNT(*) 
     FROM inventory.products p 
     WHERE p.category_id = c.id) > 5;

-- Requête imbriquée

SELECT 
    p.name AS product_name,
    (SELECT SUM(ol.quantity) 
     FROM sales.order_lines ol
     JOIN sales.orders o ON ol.order_id = o.id
     JOIN sales.customers c ON o.customer_id = c.id
     WHERE ol.sku = p.sku AND c.newsletter = true) AS total_quantity
FROM 
    inventory.products p
WHERE 
    EXISTS (
        SELECT 1 
        FROM sales.order_lines ol
        JOIN sales.orders o ON ol.order_id = o.id
        JOIN sales.customers c ON o.customer_id = c.id
        WHERE ol.sku = p.sku AND c.newsletter = true
    )
ORDER BY 
    total_quantity DESC;

-- Triggers

ALTER TABLE inventory.products 
ADD COLUMN last_updated TIMESTAMP;

CREATE TRIGGER trg_update_product_last_updated
AFTER UPDATE ON inventory.products
FOR EACH ROW
BEGIN
    IF NEW.price <> OLD.price THEN
        SET NEW.last_updated = CURRENT_TIMESTAMP;
    END IF;
END;

-- Fonctions

CREATE FUNCTION sales.get_customer_total(p_customer_id CHAR(5))
RETURNS DECIMAL(10,2)
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT SUM(p.price * ol.quantity) INTO v_total
    FROM sales.orders o
    JOIN sales.order_lines ol ON o.id = ol.order_id
    JOIN inventory.products p ON ol.sku = p.sku
    WHERE o.customer_id = p_customer_id;

    RETURN v_total;
END;

SELECT sales.get_customer_total('CU001') AS total_sales;

-- Procédures

CREATE PROCEDURE sales.create_order(
    p_customer_id CHAR(5),
    p_order_date DATE,
    p_sku VARCHAR(7),
    p_quantity INT
)
BEGIN
    DECLARE v_order_id INT;

    -- Insérer une nouvelle commande
    INSERT INTO sales.orders (customer_id, order_date)
    VALUES (p_customer_id, p_order_date);

    -- Récupérer l'ID de la commande insérée
    SET v_order_id = LAST_INSERT_ID();

    -- Insérer une ligne de commande
    INSERT INTO sales.order_lines (order_id, sku, quantity)
    VALUES (v_order_id, p_sku, p_quantity);

    -- Commit la transaction
    COMMIT;
END;

CALL sales.create_order('CU001', '2023-06-08', '1000001', 2);

-- Requêtes récursives

-- Table de création des employés
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    manager_id INT
);

-- Insertion de données exemple
INSERT INTO employees VALUES
(1, 'John Doe', NULL),     -- PDG
(2, 'Jane Smith', 1),      -- Directrice
(3, 'Bob Martin', 2),      -- Manager
(4, 'Alice Johnson', 2),   -- Manager
(5, 'Charlie Brown', 3),   -- Employé
(6, 'David Lee', 3),       -- Employé
(7, 'Eve Wilson', 4);      -- Employée

-- Requête récursive pour afficher la hiérarchie complète
WITH RECURSIVE employee_hierarchy AS (
    -- Cas de base : employés sans manager (top niveau)
    SELECT 
        employee_id, 
        name, 
        manager_id, 
        name AS hierarchy_path,
        1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Cas récursif : parcours de la hiérarchie
    SELECT 
        e.employee_id, 
        e.name, 
        e.manager_id,
        eh.hierarchy_path || ' > ' || e.name,
        eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id, 
    name, 
    hierarchy_path,
    level
FROM employee_hierarchy
ORDER BY level, employee_id;

-- Tables temporaires


CREATE TEMPORARY TABLE ma_table_temp (
    id INT,
    nom VARCHAR(100)
);


CREATE TEMP TABLE ma_table_temp AS 
SELECT * FROM ma_table_originale;