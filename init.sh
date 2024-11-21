#!/bin/bash

# Executar o docker-compose up em modo verbose
docker-compose up --verbose > docker-compose.log 2>&1 &

# Capturar o PID do processo em segundo plano
DOCKER_PID=$!

# Monitorar o arquivo de log para a mensagem específica
tail -f docker-compose.log | while read LOGLINE
do
   echo "$LOGLINE" | grep -q "INFO supervisord started with pid 1"
   if [ $? = 0 ]
   then
      echo "Mensagem detectada: INFO supervisord started with pid 1. Executando 'supervisorctl restart all'."
      supervisorctl restart all
   fi
done

# Aguardar o término do processo docker-compose
wait $DOCKER_PID

