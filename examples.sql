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

--------------------------------------------

CREATE OR REPLACE FUNCTION increment_compteur() 
RETURNS void AS $$
BEGIN
  UPDATE ma_table SET compteur = compteur + 1;
END;
$$
 LANGUAGE plpgsql VOLATILE;

CREATE TABLE employe (
 id SERIAL PRIMARY KEY,
 nom VARCHAR(50),
 age INTEGER,
 salaire NUMERIC(10,2)
);

CREATE OR REPLACE FUNCTION get_infos_employe(p_id INTEGER) 
RETURNS RECORD AS $$
DECLARE
  infos RECORD;
BEGIN
  SELECT nom, age, salaire INTO infos 
  FROM employe
  WHERE id = p_id;
  
  RETURN infos;
END;
$$
 LANGUAGE plpgsql;

 --------------------------------------------

 BEGIN
  -- code susceptible de lever une exception
EXCEPTION 
  WHEN sqlstate_no_data_found THEN
    -- traitement spécifique pour "aucune donnée trouvée"
  WHEN sqlstate_unique_violation THEN
    -- traitement spécifique pour "violation de contrainte unique"
  WHEN OTHERS THEN
    -- traitement générique pour toute autre exception
END;

--------------------------------------------

CREATE OR REPLACE PROCEDURE calculate_order_total(
    IN p_order_id INT,
    OUT p_total_amount DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Calculer le montant total de la commande
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO p_total_amount
    FROM order_items
    WHERE order_id = p_order_id;

    -- Mettre à jour le montant total dans la table des commandes
    UPDATE orders
    SET total_amount = p_total_amount
    WHERE id = p_order_id;

    -- Afficher un message de confirmation
    RAISE NOTICE 'Le montant total de la commande % a été calculé et mis à jour : %.2f', p_order_id, p_total_amount;
END;
$$
;

--------------------------------------------

-- Ajouter la colonne last_updated à la table inventory.products
ALTER TABLE inventory.products ADD COLUMN last_updated TIMESTAMP;

-- Créer une fonction trigger
CREATE OR REPLACE FUNCTION inventory.update_product_last_updated()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si le prix a changé
  IF NEW.price <> OLD.price THEN
    -- Mettre à jour le champ last_updated avec la date et l'heure courantes
    NEW.last_updated := CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$
 LANGUAGE plpgsql;

-- Créer le trigger
CREATE TRIGGER trg_update_product_last_updated
BEFORE UPDATE ON inventory.products
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION inventory.update_product_last_updated();