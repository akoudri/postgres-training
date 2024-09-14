CREATE TABLE public.temperatures
(
    id serial NOT NULL,
    measure_date date NOT NULL,
    measure_value numeric NOT NULL,
    city character varying(255) NOT NULL,
    country character varying(255) NOT NULL,
    PRIMARY KEY (id)
);

