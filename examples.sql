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