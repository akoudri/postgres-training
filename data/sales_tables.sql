----------------------------------------------------------
-- EMPTY DATABASE IN CASE IT CONTAINS CONTENT
----------------------------------------------------------

DROP TABLE IF EXISTS inventory.products;
DROP TABLE IF EXISTS inventory.categories;
DROP SCHEMA IF EXISTS inventory;
DROP TABLE IF EXISTS sales.order_lines;
DROP TABLE IF EXISTS sales.orders;
DROP TABLE IF EXISTS sales.customers;
DROP SCHEMA IF EXISTS sales;

-----------------------------------
-- CREATE THE TABLE STRUCTURE
-----------------------------------

-- Create the database schemas
CREATE SCHEMA inventory;
CREATE SCHEMA sales;


-- Create a table for the Two Trees category data
CREATE TABLE inventory.categories (
    id          	 SERIAL NOT NULL PRIMARY KEY,
    description 	 VARCHAR(50),
    product_line     VARCHAR(25)
);

-- Create a table for the Two Trees product data
CREATE TABLE inventory.products (
    sku             VARCHAR(7) NOT NULL PRIMARY KEY,
    name    	    VARCHAR(50) NOT NULL,
    category_id     INT,
    size            INT,
    price           DECIMAL(5,2) NOT NULL
);

ALTER TABLE inventory.products
ADD CONSTRAINT fk_products_category_id FOREIGN KEY (category_id)
    REFERENCES inventory.categories (id)
;

-- Create a table for the Two Trees customer data
CREATE TABLE sales.customers (
    id 		CHAR(5) NOT NULL PRIMARY KEY,
    company     VARCHAR(100),
    address     VARCHAR(100),
    city        VARCHAR(50),
    state       CHAR(2),
    zip         CHAR(5),
    newsletter  BOOLEAN
);

-- Create a table for the Two Trees order data
CREATE TABLE sales.orders (
    id     	     SERIAL NOT NULL PRIMARY KEY,
    order_date   DATE,
    customer_id  CHAR(5)
);

ALTER TABLE sales.orders
ADD CONSTRAINT fk_customers_customer_id FOREIGN KEY (customer_id)
    REFERENCES sales.customers (id)
;

-- Create a table for the order's line-item data
CREATE TABLE sales.order_lines (
    id     SERIAL NOT NULL PRIMARY KEY,
    order_id    INT,
    sku         VARCHAR(7) REFERENCES inventory.products(sku),
    quantity    INT
);

ALTER TABLE sales.order_lines
ADD CONSTRAINT fk_orders_order_id FOREIGN KEY (order_id)
    REFERENCES sales.orders (id)
;
