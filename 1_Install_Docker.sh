#!/bin/bash

# Desativar IPv6
echo "Desativando IPv6..."
sudo tee -a /etc/sysctl.conf > /dev/null <<EOL
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOL

sudo sysctl -p

# Adicionar parâmetros de inicialização do kernel
echo "Adicionando parâmetros de inicialização do kernel..."
sudo tee -a /etc/default/grub > /dev/null <<EOL
GRUB_CMDLINE_LINUX="ipv6.disable=1"
EOL

sudo update-grub

# Instalar Docker-CE
# Após o sistema reiniciar, execute o restante do script manualmente:
#!/bin/bash

echo "Instalando Docker-CE..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Adicionar chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Adicionar repositório Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker-CE
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Verificar instalação do Docker
sudo docker --version
echo "Instalação do Docker-CE concluída."

# Install Latest Docker:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin resource-agents-extra python3-distutils-extra -y

# Start Docker:
sudo systemctl enable docker
sudo systemctl restart docker

# Expand disk and mount volume:
#echo "Create VG, LV and Format " /SRV" using "/DEV/SDB" disk:"
#vgcreate vgmisp /dev/sdb1
#lvcreate -n data -l 100%FREE vgmisp
#mkfs.xfs /dev/vgmisp/data
#echo '/dev/vgmisp/data /srv         xfs     noatime        0 0' >> /etc/fstab
#mount -a && df -HT /srv
