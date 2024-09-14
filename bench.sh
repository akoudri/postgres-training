#! /bin/bash

docker exec -ti training-postgres pgbench -i training -U training
docker exec -ti training-postgres pgbench -S -c 8 -t 25000 training -U training
