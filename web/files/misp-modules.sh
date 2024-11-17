#!/bin/bash

# Instalar pacotes necessários
sudo apt install git libpq5 libjpeg-dev tesseract-ocr libpoppler-cpp-dev imagemagick virtualenv libopencv-dev zbar-tools libzbar0 libzbar-dev libfuzzy-dev libcaca-dev python3.12-venv -y

# Clonar o repositório misp-modules
sudo git clone https://github.com/MISP/misp-modules.git /usr/local/src/misp-modules
cd /usr/local/src/misp-modules

# Atualizar submódulos
sudo git submodule update --init

# Criar e ativar ambiente virtual:
sudo -u www-data python3 -m venv /var/www/MISP/venv

# Ajustar permissões do diretório venv
sudo chown -R www-data:www-data /var/www/MISP/venv

# Executar comandos dentro do ambiente virtual
sudo -u www-data /bin/bash -c '
    source /var/www/MISP/venv/bin/activate && \
    pip install poetry && \
    poetry install --with unstable && \
    pip install pyonyphe ODTReader && \
    deactivate
'

# Corrigir uso de funções descontinuadas
sudo sed -i 's/datetime.utcfromtimestamp(0)/datetime.fromtimestamp(0, datetime.UTC)/' /var/www/MISP/venv/lib/python3.12/site-packages/pytz/tzinfo.py

echo "Instalação dos MISP Modules concluída e serviço iniciado."

