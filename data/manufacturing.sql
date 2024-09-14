DROP TABLE IF EXISTS manufacturing.products;
DROP TABLE IF EXISTS manufacturing.employees;
DROP TABLE IF EXISTS manufacturing.departments;
DROP SCHEMA IF EXISTS manufacturing;

CREATE SCHEMA manufacturing;


CREATE TABLE manufacturing.services
(
    id smallint NOT NULL,
    name character varying(64) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE manufacturing.employees
(
    id integer PRIMARY KEY NOT NULL,
    firstname character varying(32) NOT NULL,
    lastname character varying(32) NOT NULL,
    service_id smallint NOT NULL,
    FOREIGN KEY (service_id)
        REFERENCES manufacturing.services (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
        NOT VALID
);
