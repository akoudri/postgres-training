DROP TABLE IF EXISTS public.people;

CREATE TABLE public.people (
	id serial not null primary key,
	name varchar(20),
	height decimal(5,2),
	gender char(1)
);
