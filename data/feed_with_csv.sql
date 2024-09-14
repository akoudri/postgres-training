\COPY manufacturing.services FROM 'data/services.csv' WITH CSV HEADER;
\COPY manufacturing.employees FROM 'data/employees.csv' WITH CSV HEADER;
\COPY public.people FROM 'data/people.csv' WITH CSV HEADER;
\COPY public.temperatures FROM 'data/temperatures.csv' WITH CSV HEADER;
\COPY public.titanic FROM 'data/titanic.csv' WITH CSV HEADER;

