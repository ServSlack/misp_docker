#!/bin/bash
echo "##################################"
echo "##################################"
echo "####___CREATE NECESSARY ENV___####"
echo "##################################"
echo "##################################"
#
cp template.env .env
#
GPG_PASSPHRASE="$(openssl rand -hex 32)"
> password.txt && echo "GPG_PASSPHRASE=$GPG_PASSPHRASE" |tee -a password.txt | tee -a .env
#
SECURITY_ENCRYPTION_KEY="$(openssl rand -hex 32)"
echo "SECURITY_ENCRYPTION_KEY=$SECURITY_ENCRYPTION_KEY" | tee -a password.txt | tee -a .env
#
MYSQL_PASSWORD="$(openssl rand -hex 32)"
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" | tee -a password.txt | tee -a .env
#
MYSQL_ROOT_PASSWORD="$(openssl rand -hex 32)"
echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" | tee -a password.txt | tee -a .env
#
MISP_USER_PASSWORD="$(openssl rand -hex 32)"
echo "MISP_USER_PASSWORD=$MISP_USER_PASSWORD" | tee -a password.txt | tee -a .env

# Execute docker-compose up em segundo plano
docker-compose up -d

# Função para monitorar logs e reiniciar o contêiner
monitor_logs_and_restart() {
#	docker cp web/files/supervisord.conf misp_web:/etc/supervisor/conf.d/supervisord.conf
#	docker cp web/files/misp-workers.conf misp_web:/etc/supervisor/conf.d/misp-workers.conf
    	docker logs -f misp_web 2>&1 | while read line; do
        echo "$line" | grep -q "INFO supervisord started with pid 1"
        if [ $? -eq 0 ]; then
            echo "Restarting container misp_web..."
            docker restart misp_web
        fi
    done
}

# Iniciar a função de monitoramento
monitor_logs_and_restart

# MISP_WEB:
docker cp web/files/first-start-misp.sh misp_web:/tmp/
docker exec misp_web chmod +x /tmp/first-start-misp.sh 
docker exec misp_web chown misp:misp /tmp/first-start-misp.sh 
docker exec misp_web bash /tmp/first-start-misp.sh
#
docker cp web/files/stix2.sh misp_web:/tmp/
docker exec misp_web chmod +x /tmp/stix2.sh
docker exec misp_web bash /tmp/stix2.sh
#
# MariaDB Tunning for " misp_db ":
docker cp misp_db:/etc/mysql/mariadb.cnf db/mariadb.cnf-bkp-misp_web
export num_cpu=$(cat /proc/cpuinfo | grep processor | wc -l | awk '{print int($1 * 0.90)}')
export innodb_buffer_pool_instances=$num_cpu
export ram_70=$(free -h | grep Mem | awk '{print $2}' | tr -d "Gi" | awk '{print int($1 * 0.7)}')
export innodb_buffer_pool_size=$ram_70
export max_connections=$((num_cpu * 10))
#
# Create MariaDB Tunned file:
cat <<EOF > db/mariadb.cnf
[mariadbd]
performance_schema=ON
performance-schema-instrument='stage/%=ON'
performance-schema-consumer-events-stages-current=ON
performance-schema-consumer-events-stages-history=ON
performance-schema-consumer-events-stages-history-long=ON

# === Required Settings ===
basedir                         = /usr
bind_address                    = 0.0.0.0 # Change to 0.0.0.0 to allow remote connections
datadir                         = /var/lib/mysql
max_allowed_packet              = 256M
max_connect_errors              = 1000000
pid_file                        = /var/run/mysqld/mysqld.pid
port                            = 3306
socket                          = /run/mysqld/mysqld.sock
secure_file_priv                = /var/lib/mysql
tmpdir                          = /tmp
user                            = mysql

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links = 0
log-error = /var/log/mysql/mysqld.log
pid-file = /var/run/mysqld/mysqld.pid

# === InnoDB Settings ===
default_storage_engine          = InnoDB
innodb_buffer_pool_instances    = ${innodb_buffer_pool_instances}
innodb_buffer_pool_size         = ${innodb_buffer_pool_size}G
innodb_file_per_table           = 1
innodb_flush_log_at_trx_commit  = 2
innodb_flush_method             = O_DIRECT
innodb_log_buffer_size          = 64M
innodb_log_file_size            = 2G
innodb_stats_on_metadata        = 0
innodb_read_io_threads          = ${num_cpu}
innodb_write_io_threads         = ${num_cpu}
innodb_io_capacity             = 4000
innodb_io_capacity_max         = 8000

# === Connection Settings ===
max_connections                 = ${max_connections}
back_log                        = 512
thread_cache_size               = ${num_cpu}
thread_stack                    = 192K

# === Buffer Settings ===
innodb_sort_buffer_size         = 2M
join_buffer_size                = 4M
read_buffer_size                = 3M
read_rnd_buffer_size            = 4M
sort_buffer_size                = 4M

# === Table Settings ===
table_definition_cache          = 40000
table_open_cache                = 40000
open_files_limit                = 65535 
max_heap_table_size             = 256M
tmp_table_size                  = 256M

# === Search Settings ===
ft_min_word_len                 = 3

# === Logging ===
log_bin=ON
binlog_format=ROW
expire_logs_days=7
log_error=/var/log/mysql/mysqld.log
log_queries_not_using_indexes=ON
long_query_time=1
slow_query_log=OFF
slow_query_log_file=/var/log/mysql/slow.log
EOF
#
docker exec -it misp_db bash -c 'apt update && apt upgrade -qy && apt install vim mysql-client pv -qy'
docker cp db/mariadb.cnf misp_db:/etc/mysql/mariadb.cnf
#
docker container restart misp_db misp_web
#
# Definir cores
export $(grep -v '^#' .env |grep 'GPG_EMAIL_ADDRESS' | xargs)
BLUE="\033[1;34m"
NC="\033[0m"

# Exibir mensagem de boas-vindas
echo -e "${BLUE}███╗   ███╗${NC}██╗███████╗██████╗ "
echo -e "${BLUE}████╗ ████║${NC}██║██╔════╝██╔══██╗"
echo -e "${BLUE}██╔████╔██║${NC}██║███████╗██████╔╝"
echo -e "${BLUE}██║╚██╔╝██║${NC}██║╚════██║██╔═══╝ "
echo -e "${BLUE}██║ ╚═╝ ██║${NC}██║███████║██║     "
echo -e "${BLUE}╚═╝     ╚═╝${NC}╚═╝╚══════╝╚═╝     "
echo -e "v2.5 Setup on Ubuntu 24.04 LTS"

# Função para salvar configurações
save_settings() {
#    settings="[$(date)] MISP installation
    settings="[$(date)] MISP installation

[MISP admin user]
- Admin Username: admin@admin.test
- Admin Password: admin

[MYSQL ADMIN]
- Username: root
- Password: ${MYSQL_ROOT_PASSWORD}

[MYSQL MISP]
- Username: misp 
- Password: ${MISP_USER_PASSWORD}

[MISP internal]
- GPG Email: ${GPG_EMAIL_ADDRESS}
- GPG Passphrase: ${GPG_PASSPHRASE}
- Security Encryption: ${SECURITY_ENCRYPTION_KEY}
"

    # Exibir as configurações na tela
    echo "$settings"

    # Salvar as configurações no arquivo misp_settings.txt
    echo "$settings" | tee /var/log/misp_settings.txt
}

# Remove "template_build.env"
rm .env

# Chamar a função save_settings para salvar e exibir as configurações
save_settings
