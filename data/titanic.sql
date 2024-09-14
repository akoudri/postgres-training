CREATE TABLE public.titanic
(
    id integer NOT NULL,
    pclass smallint NOT NULL,
    survived smallint NOT NULL,
    sex char varying(8) NOT NULL,
    age double precision NOT NULL,
    PRIMARY KEY (id)
);
