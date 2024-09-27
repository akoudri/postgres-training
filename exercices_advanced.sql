---------- CTE --------------

WITH 
  product_stats AS (
    SELECT 
      c.description AS category,
      COUNT(*) AS product_count,
      AVG(p.price) AS avg_price
    FROM 
      inventory.products p
      JOIN inventory.categories c ON p.category_id = c.id
    GROUP BY 
      c.description
  ),
  order_stats AS (
    SELECT 
      c.description AS category,
      COUNT(DISTINCT o.id) AS order_count,
      SUM(ol.quantity) AS total_quantity
    FROM 
      sales.order_lines ol
      JOIN inventory.products p ON ol.sku = p.sku
      JOIN inventory.categories c ON p.category_id = c.id
      JOIN sales.orders o ON ol.order_id = o.id
    GROUP BY 
      c.description
  )
SELECT 
  ps.category,
  ps.product_count,
  ps.avg_price,
  os.order_count,
  os.total_quantity
FROM 
  product_stats ps
  JOIN order_stats os ON ps.category = os.category;


----------- Sous-Requêtes -----------------------

SELECT 
  p.name AS product_name,
  p.price AS product_price,
  (SELECT MAX(o.order_date) 
   FROM sales.orders o
   JOIN sales.order_lines ol ON o.id = ol.order_id
   WHERE ol.sku = p.sku) AS last_order_date,
  (SELECT COUNT(*) 
   FROM sales.order_lines ol
   WHERE ol.sku = p.sku) AS order_count,
  (SELECT SUM(ol.quantity)
   FROM sales.order_lines ol
   WHERE ol.sku = p.sku) AS total_quantity
FROM 
  inventory.products p
WHERE 
  EXISTS (
    SELECT 1 
    FROM sales.order_lines ol
    WHERE ol.sku = p.sku
  );

----------- Requêtes imbriquées -----------

SELECT 
  c.company AS customer,
  (SELECT COUNT(*) 
   FROM sales.orders o
   WHERE o.customer_id = c.id) AS total_orders,
  (SELECT SUM(ol.quantity * p.price)
   FROM sales.orders o
   JOIN sales.order_lines ol ON o.id = ol.order_id
   JOIN inventory.products p ON ol.sku = p.sku
   WHERE o.customer_id = c.id) AS total_amount,
  (SELECT MAX(o.order_date)
   FROM sales.orders o
   WHERE o.customer_id = c.id) AS last_order_date,
  (SELECT p.name
   FROM sales.orders o
   JOIN sales.order_lines ol ON o.id = ol.order_id
   JOIN inventory.products p ON ol.sku = p.sku
   WHERE o.customer_id = c.id
   ORDER BY p.price DESC
   LIMIT 1) AS most_expensive_product,
  (SELECT ol.quantity
   FROM sales.orders o
   JOIN sales.order_lines ol ON o.id = ol.order_id
   JOIN inventory.products p ON ol.sku = p.sku
   WHERE o.customer_id = c.id
   ORDER BY p.price DESC
   LIMIT 1) AS quantity_most_expensive,
  (SELECT p.price
   FROM sales.orders o
   JOIN sales.order_lines ol ON o.id = ol.order_id
   JOIN inventory.products p ON ol.sku = p.sku
   WHERE o.customer_id = c.id
   ORDER BY p.price DESC
   LIMIT 1) AS price_most_expensive
FROM 
  sales.customers c
WHERE 
  EXISTS (
    SELECT 1 
    FROM sales.orders o
    WHERE o.customer_id = c.id
  );

---------- Procédures stockées ---------------

CREATE OR REPLACE PROCEDURE inventory.add_product(
  p_sku VARCHAR(7),
  p_name VARCHAR(50),
  p_category_id INT,
  p_size INT,
  p_price DECIMAL(5,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows_inserted INT;
BEGIN
  INSERT INTO inventory.products (sku, name, category_id, size, price)
  VALUES (p_sku, p_name, p_category_id, p_size, p_price);
  
  GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;
  
  RAISE NOTICE 'Inserted % row(s) into inventory.products', v_rows_inserted;
END;
$$
;

CREATE OR REPLACE PROCEDURE inventory.update_product_price(
  p_sku VARCHAR(7),
  p_percentage DECIMAL(5,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_new_price DECIMAL(5,2);
BEGIN
  UPDATE inventory.products 
  SET price = price * (1 + p_percentage / 100)
  WHERE sku = p_sku
  RETURNING price INTO v_new_price;
  
  RAISE NOTICE 'Updated price for product % to %', p_sku, v_new_price;
END;
$$
;

CREATE OR REPLACE PROCEDURE sales.place_order(
  p_customer_id CHAR(5),
  p_order_date DATE,
  p_items TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id INT;
  v_sku VARCHAR(7);
  v_quantity INT;
BEGIN
  INSERT INTO sales.orders (customer_id, order_date)
  VALUES (p_customer_id, p_order_date)
  RETURNING id INTO v_order_id;
  
  FOR v_sku, v_quantity IN 
    SELECT TRIM(SPLIT_PART(item, ',', 1)), TRIM(SPLIT_PART(item, ',', 2))::INT
    FROM REGEXP_SPLIT_TO_TABLE(p_items, E'\\|') AS item
  LOOP
    INSERT INTO sales.order_lines (order_id, sku, quantity)
    VALUES (v_order_id, v_sku, v_quantity);
  END LOOP;
  
  RAISE NOTICE 'Placed order % with % line item(s)', v_order_id, COUNT(*) FROM sales.order_lines WHERE order_id = v_order_id;
END;
$$
;

---------------- Triggers -------------------

-- Créer la fonction du trigger
CREATE OR REPLACE FUNCTION update_newsletter_subscription()
  RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM sales.customers 
    WHERE id = NEW.customer_id AND newsletter = true
  ) THEN
    UPDATE sales.customers 
    SET newsletter = true
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$
 LANGUAGE plpgsql;

-- Créer le trigger
CREATE TRIGGER trg_update_newsletter
AFTER INSERT ON sales.orders
FOR EACH ROW
EXECUTE FUNCTION update_newsletter_subscription();

-- Créer la table inventory.reorder si elle n'existe pas déjà
CREATE TABLE IF NOT EXISTS inventory.reorder (
  sku VARCHAR(7) REFERENCES inventory.products(sku),
  reorder_date DATE
);

-- Fonction trigger
CREATE OR REPLACE FUNCTION check_quantity_and_reorder()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si la quantité est supérieure à 10
  IF NEW.quantity > 10 THEN
    -- Insérer un enregistrement dans la table inventory.reorder
    INSERT INTO inventory.reorder (sku, reorder_date)
    VALUES (NEW.sku, CURRENT_DATE);
  END IF;
  
  -- Propager l'opération d'insertion/mise à jour à la table sales.order_lines
  RETURN NEW;
END;
$$
 LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_check_quantity_and_reorder
AFTER INSERT OR UPDATE ON sales.order_lines
FOR EACH ROW
EXECUTE FUNCTION check_quantity_and_reorder();

----------- Requêtes ---------------------

select * from inventory.products
where price between 10 and 20;

select employees.firstname, employees.lastname, services.name as service from manufacturing.employees as employees
left join manufacturing.services as services
on employees.service_id = services.id
where services.name = 'Manufacturing';

select * from manufacturing.employees
where employees.lastname like 'F%';

select * from manufacturing.employees
where employees.firstname ilike 'D%E';

create view manufacturing.members
as
select firstname, lastname, name
from manufacturing.employees
left join manufacturing.services
on employees.service_id = services.id;

create role rh with login;
grant select on table manufacturing.employees to rh;
alter role rh with password 'training';


---------- Agrégations -----------------

select size, count(*) as nb
from inventory.products
group by size
order by nb;

select state, count(*)
from sales.customers
group by state;

select name, round(avg(price), 2) as avg_price from inventory.products
group by name
order by avg_price;

select name, max(price) - min(price) as diff from inventory.products
group by name
order by name;

SELECT state, count(*), bool_and(newsletter) 
FROM sales.customers 
GROUP BY state;

select gender, count(*), round(avg(height), 2) as avg, 
	min(height), max(height), round(variance(height), 2) as var, 
	round(stddev(height), 2) as std
from people
group by gender;

select category_id, size, count(*),
	min(price) as "lowest price",
	max(price) as "highest price",
	round(avg(price), 2) as "average price"
from inventory.products
group by rollup(category_id, size)
order by category_id, size;

select 
	gender,
	count(*) filter (where height < 170) as cat1,
	avg(height) filter (where height < 170) as avg1,
	count(*) filter (where height >= 170) as cat2,
	avg(height) filter (where height >= 170) as avg2
from people
group by rollup(gender);

SELECT 
    name, 
    size, 
    MIN(price) OVER(PARTITION BY name, size) AS min_price,
    MAX(price) OVER(PARTITION BY name, size) AS max_price,
    AVG(price) OVER(PARTITION BY name, size) AS avg_price
FROM inventory.products;

SELECT 
    name, 
    size, 
    MIN(price) OVER(wnd) AS min_price,
    MAX(price) OVER(wnd) AS max_price,
    AVG(price) OVER(wnd) AS avg_price
FROM inventory.products
WINDOW wnd AS (PARTITION BY name, size);

SELECT
  customer_id,
  EXTRACT(YEAR FROM order_date) AS order_year,
  EXTRACT(MONTH FROM order_date) AS order_month,
  COUNT(customer_id) AS order_count
FROM
  sales.orders
GROUP BY
  customer_id,
  order_year,
  order_month
ORDER BY
  customer_id,
  order_year ASC,
  order_month ASC;
  
-- select sku, sum(quantity) as "total" 
-- from sales.order_lines
-- group by(sku)
-- order by total desc;

with tab as (
	select 
		order_lines.order_id as id, 
		products.sku as sku, 
		quantity, 
		price, 
		quantity * price as prod
	from sales.order_lines
	left join inventory.products on order_lines.sku = products.sku
)
select 
	id, sku, quantity, price, prod, 
	sum(prod) over (partition by id order by sku) as cum
from tab;
	

SELECT
	company,
	ROW_NUMBER() OVER (ORDER BY company) AS row_number,
	FIRST_VALUE(company) OVER (ORDER BY company) AS first_value,
	LAST_VALUE(company) OVER (ORDER BY company RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_value,
	NTH_VALUE(company, 3) OVER (ORDER BY company) AS nth_value
FROM sales.customers;

select distinct
	customer_id,
	first_value(order_date) over (partition by customer_id order by order_date asc) as first,
	last_value(order_date) over (partition by customer_id order by order_date asc rows between unbounded preceding and unbounded following) as last
from sales.orders;

select name, gender, height,
	rank() over (partition by gender order by height desc),
	dense_rank() over (partition by gender order by height desc)
from people
order by gender, height desc;

select
	mode() within group (order by height)
from public.people;

SELECT round(height), COUNT(*)
FROM public.people
GROUP BY round(height);

--OR

SELECT DISTINCT height,
       COUNT(*) OVER (PARTITION BY height) as count
FROM public.people;

SELECT
	gender,
	percentile_disc(0.25) within group (order by height) as "0.25",
	percentile_disc(0.5) within group (order by height) as "0.5",
	percentile_disc(0.75) within group (order by height) as "0.75"
FROM people
GROUP by rollup(gender);

select
	category_id,
	min(price) as "min_price",
	percentile_disc(0.25) within group (order by price) as "1st quantile",
	percentile_disc(0.5) within group (order by price) as "2nd quantile",
	percentile_disc(0.75) within group (order by price) as "3rd quantile",
	max(price) as "min_price",
	max(price) - min(price) as "range",
	round(avg(price), 2) as avg
from inventory.products
group by category_id;

select sku,
	name,
	size,
	category_id,
	price,
	avg(price) over(partition by size) as "average price for size",
	price - avg(price) over(partition by size) as "difference"
from inventory.products
order by sku, size;

select id, sum(id) over (partition by id) as "sum"
from inventory.categories;

select order_lines.order_id,
	order_lines.id,
	order_lines.sku,
	order_lines.quantity,
	products.price as "price each",
	order_lines.quantity * products.price as "line total",
	sum (order_lines.quantity * products.price)
		over (partition by order_id) as "order total",
	sum (order_lines.quantity * products.price)
		over (order by id) as "cumul total"
from sales.order_lines inner join inventory.products
	on order_lines.sku = products.sku;
	
select
	id,
	sum(id) over(order by id rows between 0 preceding and 2 following)
from sales.orders;

select
	percentile_disc(0.5) within group (order by height) as "discrete median",
	percentile_cont(0.5) within group (order by height) as "discrete median"
from people;

select name, height, ntile(4) over (order by height)
from people order by height;

SELECT
    pclass,
    sex,
	case
		when age < 20 then '-20'
		when age >= 20 and age < 40 then '20-40'
		when age >= 40 and age < 60 then '40-60'
		else '60+'
	end as category,
    COUNT(*) AS total_people,
    SUM(survived) / COUNT(*)::float AS survival_rate
FROM public.titanic
GROUP BY pclass, sex, category
ORDER BY survival_rate;

----------------- SERIES TEMPORELLES ----------------

SELECT 
    t.city,
    t.country,
    ROUND(MIN(t.measure_value), 2) AS min,
    ROUND(MAX(t.measure_value), 2) AS max,
    ROUND(AVG(t.measure_value), 2) AS mean,
    ROUND((MAX(t.measure_value) - MIN(t.measure_value)), 2) AS interval,
    ROUND(STDDEV(t.measure_value), 2) AS dev,
    c.nb_cities
FROM public.temperatures t
JOIN (
    SELECT 
        country,
        COUNT(DISTINCT city) AS nb_cities
    FROM public.temperatures
    GROUP BY country
) c ON t.country = c.country
GROUP BY t.city, t.country, c.nb_cities
ORDER BY t.country, t.city;

SELECT 
    EXTRACT(YEAR FROM measure_date) AS year,
    ROUND(AVG(measure_value), 2) AS avg_annual_temperature
FROM public.temperatures
WHERE 
    city = 'Paris' AND 
    EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
GROUP BY year
ORDER BY year;

SELECT CORR(paris, new_york) as corr_coeff
FROM (
	SELECT 
		EXTRACT(YEAR FROM measure_date) AS year,
		AVG(CASE WHEN city = 'Paris' THEN measure_value END) AS paris,
		AVG(CASE WHEN city = 'New York' THEN measure_value END) AS new_york
	FROM public.temperatures
	WHERE 
		(city = 'Paris' OR city = 'New York') AND 
		EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
	GROUP BY year
	ORDER BY year
) AS annual_temperatures;

WITH RankedTemperatures AS (
    SELECT
        EXTRACT(YEAR FROM measure_date) AS year,
        CASE 
            WHEN EXTRACT(MONTH FROM measure_date) <= 6 THEN 'First Half'
            ELSE 'Second Half'
        END AS half_year,
        measure_value AS temperature,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM measure_date), 
            CASE WHEN EXTRACT(MONTH FROM measure_date) <= 6 THEN 'First Half' ELSE 'Second Half' END
            ORDER BY measure_date
        ) AS row_num
    FROM public.temperatures
    WHERE 
        city = 'Paris' AND
        EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
)
SELECT year, half_year, temperature
FROM RankedTemperatures
WHERE row_num = 1
ORDER BY year, half_year;

SELECT
    date_trunc('decade', measure_date) AS decade_start,
    ROUND(AVG(measure_value), 2) AS avg_temperature
FROM public.temperatures
WHERE 
    city = 'Paris' AND
    measure_date BETWEEN '1900-01-01' AND '1999-12-31'
GROUP BY decade_start
ORDER BY decade_start;

SELECT
    year,
    AVG(avg_temperature) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS moving_avg_temperature
FROM (
    SELECT
        EXTRACT(year FROM measure_date) AS year,
        AVG(measure_value) AS avg_temperature
    FROM public.temperatures
    WHERE 
        city = 'Paris' AND
        measure_date BETWEEN '1900-01-01' AND '1999-12-31'
    GROUP BY year
) AS yearly_avg_temperatures
ORDER BY year;

with tab as (
	select measure_date, round(measure_value, 2) as measure
	from temperatures
	where city='Paris' 
		and (extract(year from measure_date) between 1900 and 2000)
	order by measure_date
)
select measure_date, 
	measure, 
	measure - lag(measure) over() as diff
from tab;

----------------- PARTITIONS ------------------------

ALTER TABLE public.people RENAME TO old_people;

CREATE TABLE public.people (
    id serial not null,
    name varchar(20),
    height decimal(5,2),
    gender char(1)
) PARTITION BY LIST (gender);

CREATE TABLE public.people_male PARTITION OF public.people FOR VALUES IN ('m');
CREATE TABLE public.people_female PARTITION OF public.people FOR VALUES IN ('f');

ALTER TABLE public.people_male ADD PRIMARY KEY (id);
ALTER TABLE public.people_female ADD PRIMARY KEY (id);

INSERT INTO public.people SELECT * FROM old_people;

DROP TABLE old_people;

--OPTIONNEL: si d'autres catégories viennent se rajouter

CREATE TABLE public.people_trans PARTITION OF public.people FOR VALUES IN ('t');
ALTER TABLE public.people ATTACH PARTITION public.people_trans FOR VALUES IN ('t');


CREATE TABLE public.new_temperatures (
    id serial NOT NULL,
    measure_date date NOT NULL,
    measure_value numeric NOT NULL,
    city character varying(255) NOT NULL,
    country character varying(255) NOT NULL,
    PRIMARY KEY (id, country)
) PARTITION BY LIST (country);

DO $$ 
DECLARE 
    country_name VARCHAR(255);
    escaped_country_name VARCHAR(255);
BEGIN 
    FOR country_name IN (SELECT DISTINCT country FROM public.temperatures)
    LOOP
        escaped_country_name := replace(country_name, '''', '''''');

        EXECUTE format('CREATE TABLE %I PARTITION OF public.new_temperatures FOR VALUES IN (''%s'')', 
                       'temperatures_' || replace(country_name, ' ', '_'), escaped_country_name);
    END LOOP;
END $$;

INSERT INTO public.new_temperatures SELECT * FROM public.temperatures;

ALTER TABLE public.temperatures RENAME TO temperatures_old;
ALTER TABLE public.new_temperatures RENAME TO temperatures;

--------------------- VACUUM --------------------------------

INSERT INTO public.people (id, name, height, gender)
SELECT 
	ROW_NUMBER() OVER() + 1000 ,
    SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 10),
    (100.0 + (RANDOM() * 100.0))::DECIMAL(5,2),
    CASE WHEN RANDOM() < 0.5 THEN 'm' ELSE 'n' END
FROM generate_series(1, 100000);

DELETE FROM people WHERE id > 1000 AND id < 70000;


--------------------- INDEX ---------------------------------------

CREATE INDEX idx_orders_delivery_address_gin ON public.orders USING gin (delivery_address gin_trgm_ops);

CREATE INDEX idx_orders_order_date ON public.orders (order_date);

CREATE INDEX idx_orders_order_status ON public.orders (order_status) WHERE order_status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled');

CREATE INDEX idx_orders_customer_id_product_id ON public.orders (customer_id, product_id);

------------------------HINTS----------------------------------------

CREATE INDEX idx_people_height ON public.people (height);

SELECT /*+ SeqScan(p) */ * 
FROM public.people p
WHERE height > 1.80;

SELECT /*+ IndexScan(p idx_people_height) */ *
FROM public.people p
WHERE height BETWEEN 1.60 AND 1.80;

SELECT /*+ IndexOnlyScan(p idx_people_height_name) */ name, height
FROM public.people p
ORDER BY height DESC
LIMIT 10;

DROP INDEX idx_people_height;
CREATE INDEX idx_people_height_name ON public.people (height, name);

SELECT /*+ BitmapScan(p idx_people_gender) */ gender, count(*) 
FROM public.people p
GROUP BY gender;

SELECT /*+ IndexScan(p idx_people_height) SeqScan(p) */ name
FROM public.people p
WHERE height > 1.90 OR height < 1.60;

CREATE INDEX idx_people_gender ON public.people (gender);

CREATE TABLE public.account (
    id serial not null primary key,
    code varchar(20),
    person_id integer references public.people(id)
);

CREATE INDEX idx_people_id ON public.people (id);
CREATE INDEX idx_account_person_id ON public.account (person_id);

SELECT /*+ HashJoin(p s) */ p.name
FROM public.people p
JOIN public.account a ON p.id = a.person_id
WHERE a.code = 'XXXX';

SELECT /*+ MergeJoin(p s) */ p.name
FROM public.people p
JOIN public.account a ON p.id = a.person_id
WHERE a.code = 'XXXX';

--------------------- QUIZZ -------------------------------------

-- 2. b, 3. d, 4. b, 5. c, 6. a, 8. d

