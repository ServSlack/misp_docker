FROM ubuntu:24.04

# Install MISP CORE components
USER root
# Atualizar e instalar pacotes necessários
RUN apt-get update -y && \
    apt-get dist-upgrade -qy && apt-get upgrade && apt-get autoremove -y && apt-get clean && \
    apt-get install -qy software-properties-common && \
    apt-get install -qy postfix rsyslog systemd systemd-sysv && \
    apt-get install -qy mysql-client curl gcc git gnupg-agent bash \
    make cmake openssl redis-server sudo vim zip locales wget iproute2 supervisor cron libfuzzy-dev librdkafka-dev \
    libffi-dev libbrotli1 librdkafka1 libfuzzy2 libsimdjson-dev ssdeep clamav clamav-daemon python3 python3-pip \
    python3-virtualenv python3.12-venv apache2 binutils libbrotli-dev libzstd-dev net-tools ntpsec iputils-ping \
    python3-xyzservices tzdata
#
#
ADD template.env /tmp/.env
RUN export $(cat /tmp/.env | grep -v '#' | awk '/=/ {print $1}')
#
# Criar o usuário misp e definir a senha misp
RUN useradd -m -s /bin/bash -m -G adm,cdrom,sudo,dip,plugdev,www-data,staff,crontab misp
#RUN echo "misp:misp" | chpasswd
RUN echo "misp:misp" | chpasswd
#
# Configurar sudo para não pedir senha ao usuário misp
RUN echo "misp ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#
# Definir o usuário misp como padrão ao iniciar o contêiner
ADD files/localtime /etc/localtime
ADD files/ntp.conf /etc/ntpsec/ 
#
ADD run.sh /run.sh 
RUN sudo chmod +x /run.sh 
#
ADD files/first-start-misp.sh /tmp/ 
RUN sudo chmod +x /tmp/first-start-misp.sh
#
ADD files/misp.cron.d /etc/cron.d/misp
ADD files/entrypoint_cron.sh /
RUN sudo chmod +x /entrypoint_cron.sh 
#
ADD files/misp-workers.conf /etc/supervisor/conf.d/misp-workers.conf
ADD files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#
# Install script
COPY --chown=misp:misp INSTALL.sh /tmp/
RUN sudo chmod +x /tmp/INSTALL.sh
#
USER misp
WORKDIR /var/www/MISP
RUN sudo bash /tmp/INSTALL.sh
#
USER root
ADD files/misp-modules.sh /tmp/ 
RUN chmod +x /tmp/misp-modules.sh 
RUN bash /tmp/misp-modules.sh
#
RUN apt install python3-pip python3-venv -y
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
#
RUN pip install --upgrade pip
#
RUN pip3 list -o | awk 'NR>2 {print $1}' | xargs -r -n1 pip3 install -U ; exit 0
#
# Add run script
COPY --chown=root:root run.sh /run.sh
COPY --chown=root:root wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN ln -s /usr/local/bin/wait-for-it.sh /wait-for-it.sh
RUN chmod 0755 /run.sh && touch /.firstboot.tmp
#
# Make a backup of /var/www/MISP to restore it to the local moint point at first boot
WORKDIR /var/www/MISP
RUN sudo tar czpf /root/MISP.tgz .
#
VOLUME /var/www/MISP
EXPOSE 80
ENTRYPOINT ["/run.sh"]
