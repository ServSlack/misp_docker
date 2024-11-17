#!/bin/bash
# 1MISP 2.5 installation for Ubuntu 24.04 LTS

# This guide is meant to be a simply installation of MISP on a pristine Ubuntu 20.04 LTS server.
# Keep in mind that whilst this installs the software along with all of its dependencies, it's up to you to properly secure it.

# This guide liberally borrows from three sources:
# - The previous iterations of the official MISP installation guide, which can be found at: https://misp.github.io/MISP
# - The automisp install guide by @da667, which can be found at: https://github.com/da667/AutoMISP/blob/master/auto-MISP-ubuntu.sh
# - MISP-docker by @ostefano, which can be found at: https://github.com/MISP/MISP-docker
# Thanks to both Tony Robinson (@da667), Stefano Ortolani (@ostefano) and Steve Clement (@SteveClement) for their awesome work!

# This installation script assumes that you are installing as root, or a user with sudo access.

random_string() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
}

# Configure the following variables in advance for your environment
## required settings - please change all of these, failing to do so will result in a non-working installation or a highly insecure installation
PASSWORD="$(random_string)"
ENCRIPTION_KEY="$(random_string)"
MISP_DOMAIN='misp.local'
PATH_TO_SSL_CERT=''
INSTALL_SSDEEP='y' # y/n, if you want to install ssdeep, set to 'y', however, this will require the installation of make

## optional settings
MISP_PATH='/var/www/MISP'
APACHE_USER='www-data'

### DB settings, if you want to use a different DB host, name, user, or password, please change these
DBHOST='localhost'
DBUSER_ADMIN='root'
DBPASSWORD_ADMIN='' # Default on Ubuntu is a passwordless root account, if you have changed it, please set it here
DBNAME='misp'
DBPORT='3306'
DBUSER_MISP='misp'
DBPASSWORD_MISP="$(random_string)"

### Supervisor settings
SUPERVISOR_USER='supervisor'
SUPERVISOR_PASSWORD="$(random_string)"

### PHP settings
upload_max_filesize="50M"
post_max_size="50M"
max_execution_time="300"
memory_limit="4096M"

## GPG
GPG_EMAIL_ADDRESS="admin@admin.test"
GPG_PASSPHRASE="$(openssl rand -hex 32)"

### Only needed if no SSL CERT is provided
OPENSSL_C='BR'
OPENSSL_ST='Rio de Janeiro'
OPENSSL_L='RJ'
OPENSSL_O='MISP'
OPENSSL_OU='MISP'
OPENSSL_CN=${MISP_DOMAIN}
OPENSSL_EMAILADDRESS='misp@'${MISP_DOMAIN}

# Some helper functions shamelessly copied from @da667's automisp install script.

logfile=/var/log/misp_install.log
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
sudo rm ${logfile}.pipe

function install_packages()
{
    install_params=("$@")
    for i in "${install_params[@]}";
    do
        sudo apt install -y "$i" &>> $logfile
        error_check "$i installation"
    done
}


function error_check
{
    if [ $? -eq 0 ]; then
        print_ok "$1 successfully completed."
    else
        print_error "$1 failed. Please check $logfile for more details."
    exit 1
    fi
}

function print_status ()
{
    echo -e "\x1B[01;34m[STATUS]\x1B[0m $1"
}

function print_ok ()
{
    echo -e "\x1B[01;32m[OK]\x1B[0m $1"
}

function print_error ()
{
    echo -e "\x1B[01;31m[ERROR]\x1B[0m $1"
}

function print_notification ()
{
	echo -e "\x1B[01;33m[NOTICE]\x1B[0m $1"
}

function os_version_check ()
{
    # Check if we're on Ubuntu 24.04 as expected:
    UBUNTU_VERSION=$(lsb_release -a | grep Release | grep -oP '[\d-]+.[\d-]+$')
    if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
        print_error "This upgrade tool expects you to be running Ubuntu 24.04. If you are on a prior upgrade of Ubuntu, please make sure that you upgrade your distribution first, then execute this script again."
        exit 1
    fi
}

BLUE="\033[1;34m"
NC="\033[0m"
echo -e "${BLUE}███╗   ███╗${NC}██╗███████╗██████╗ "
echo -e "${BLUE}████╗ ████║${NC}██║██╔════╝██╔══██╗"
echo -e "${BLUE}██╔████╔██║${NC}██║███████╗██████╔╝"
echo -e "${BLUE}██║╚██╔╝██║${NC}██║╚════██║██╔═══╝ "
echo -e "${BLUE}██║ ╚═╝ ██║${NC}██║███████║██║     "
echo -e "${BLUE}╚═╝     ╚═╝${NC}╚═╝╚══════╝╚═╝     "
echo -e "v2.5 Setup on Ubuntu 24.04 LTS"

os_version_check

# Configurar permissões para o log do MISP
print_status "Updating base system..."
sudo apt-get update &>> $logfile
sudo apt-get upgrade -y &>> $logfile
error_check "Base system update"

print_status "Installing apt packages (git curl python3 python3-pip python3-virtualenv apache2 zip gcc sudo binutils openssl supervisor libfuzzy-dev libbrotli-dev librdkafka-dev libsimdjson-dev libzstd-dev net-tools vim ntpsec locales)..."
declare -a packages=( git curl python3 python3-pip python3-virtualenv apache2 zip gcc sudo binutils openssl supervisor libfuzzy-dev libbrotli-dev librdkafka-dev libsimdjson-dev libzstd-dev net-tools vim ntpsec locales );
install_packages ${packages[@]}
error_check "Basic dependencies installation"

# Grant Brazilian Local Time:
sudo dpkg-reconfigure -fnoninteractive tzdata
sudo service ntpsec restart
systemctl enable ntpsec
error_check "NTPSec restart"

print_status "Installing PHP and the list of required extensions..."
declare -a packages=( redis-server php8.3 php8.3-cli php8.3-dev php8.3-xml php8.3-mysql php8.3-opcache php8.3-readline php8.3-mbstring php8.3-zip \
  php8.3-intl php8.3-bcmath php8.3-gd php8.3-redis php8.3-gnupg php8.3-apcu libapache2-mod-php8.3 php8.3-curl );
install_packages ${packages[@]}
PHP_ETC_BASE=/etc/php/8.3
PHP_INI=${PHP_ETC_BASE}/apache2/php.ini
error_check "PHP and required extensions installation."

# Install composer and the composer dependencies of MISP

print_status "Installing composer..."

## make pip and composer happy
sudo mkdir /var/www/.cache/
sudo chown -R ${APACHE_USER}:${APACHE_USER} /var/www/.cache/

curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php &>> $logfile
COMPOSER_HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"  &>> $logfile
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer  &>> $logfile
error_check "Composer installation"

print_status "Configuring php and MySQL configs..."
for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit
do
    sudo sed -i "s/^\($key\).*/\1 = $(eval echo \${$key})/" $PHP_INI
done
sudo sed -i "s/^\(session.sid_length\).*/\1 = 32/" $PHP_INI
sudo sed -i "s/^\(session.use_strict_mode\).*/\1 = 1/" $PHP_INI
sudo sed -i "s/^\(session.save_handler\).*/\1 = redis/" $PHP_INI
sudo sed -i "/session.save_handler/a session.save_path = 'tcp:\/\/localhost:6379'/" $PHP_INI

# Check for cgroup memory limits, don't rely on /proc/meminfo in an LXC container with unbound memory limits
# Thanks to Sascha Rommelfangen (@rommelfs) for the hint
CGROUPMEMORYHIGHPATH="/sys/fs/cgroup/memory.high"
if [ -f $CGROUPMEMORYHIGHPATH ] && [[ "cat ${CGROUPMEMORYHIGHPATH}" == "max" ]]; then
    INNODBBUFFERPOOLSIZE='2048M'
else
    INNODBBUFFERPOOLSIZE=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 2048)}')'M'
fi

sudo service apache2 restart
error_check "Apache restart"

print_ok "PHP configured..."

print_status "Installing PECL extensions..."

sudo pecl channel-update pecl.php.net &>> $logfile
sudo pecl install brotli &>> $logfile
error_check "PECL brotli extension installation"
sudo pecl install simdjson &>> $logfile
error_check "PECL simdjson extension installation"
sudo pecl install zstd &>> $logfile
error_check "PECL zstd extension installation"
sudo printf "autodetect\n" | sudo pecl install rdkafka &>> $logfile
error_check "PECL rdkafka extension installation"

if [ $INSTALL_SSDEEP == "y" ]; then
    sudo apt install make -y &>> $logfile
    error_check "The installation of make"
    sudo cp "/usr/lib/$(gcc -dumpmachine)"/libfuzzy.* /usr/lib
    git clone --recursive --depth=1 https://github.com/JakubOnderka/pecl-text-ssdeep.git /tmp/pecl-text-ssdeep
    error_check "Jakub Onderka's PHP8 SSDEEP extension cloning"
    cd /tmp/pecl-text-ssdeep && phpize && ./configure && make && make install
    error_check "Jakub Onderka's PHP8 SSDEEP extension compilation and installation"
fi

sudo cp /usr/lib/php/20230831/ssdeep.so /usr/lib/php/8.3/ssdeep.so
sudo cp /usr/lib/php/20230831/brotli.so /usr/lib/php/8.3/brotli.so
sudo cp /usr/lib/php/20230831/simdjson.so /usr/lib/php/8.3/simdjson.so
sudo cp /usr/lib/php/20230831/zstd.so /usr/lib/php/8.3/zstd.so
sudo cp /usr/lib/php/20230831/rdkafka.so /usr/lib/php/8.3/rdkafka.so

sudo sh -c 'for dir in /etc/php/*; do echo "extension=ssdeep.so" > "$dir/mods-available/ssdeep.ini"; done; phpenmod redis; phpenmod ssdeep'
sudo sh -c 'for dir in /etc/php/*; do echo "extension=brotli.so" > "$dir/mods-available/brotli.ini"; done ;phpenmod brotli'
sudo sh -c 'for dir in /etc/php/*; do echo "extension=simdjson.so" > "$dir/mods-available/simdjson.ini"; done ;phpenmod simdjson'
sudo sh -c 'for dir in /etc/php/*; do echo "extension=zstd.so" > "$dir/mods-available/zstd.so.ini"; done ;phpenmod zstd.so'
sudo sh -c 'for dir in /etc/php/*; do echo "extension=rdkafka.so" > "$dir/mods-available/rdkafka.ini"; done; phpenmod rdkafka'

print_status "Cloning MISP"
sudo git clone https://github.com/MISP/MISP.git ${MISP_PATH}  &>> $logfile
error_check "MISP clonining"
cd ${MISP_PATH}
git fetch origin 2.5 &>> $logfile
error_check "Fetching 2.5 branch"
git checkout 2.5 &>> $logfile
error_check "Checking out 2.5 branch"

print_status "Cloning MISP submodules..."
sudo git config --global --add safe.directory ${MISP_PATH}  &>> $logfile
sudo git -C ${MISP_PATH} submodule update --init --recursive &>> $logfile
error_check "MISP submodules cloning"
sudo git -C ${MISP_PATH} submodule foreach --recursive git config core.filemode false &>> $logfile
sudo chown -R ${APACHE_USER}:${APACHE_USER} ${MISP_PATH} &>> $logfile
sudo chown -R ${APACHE_USER}:${APACHE_USER} ${MISP_PATH}/.git &>> $logfile
print_ok "MISP's submodules cloned."

print_status "Installing MISP composer dependencies..."
cd ${MISP_PATH}/app
sudo -u ${APACHE_USER} composer install --no-dev --no-interaction --prefer-dist &>> $logfile
sudo printf "y\n" | sudo -u ${APACHE_USER} php composer.phar require --with-all-dependencies elasticsearch/elasticsearch aws/aws-sdk-php jakub-onderka/openid-connect-php
error_check "MISP composer dependencies installation"

print_status "Moving and configuring MISP php config files.."
cd ${MISP_PATH}/app/Config
cp -a bootstrap.default.php bootstrap.php
cp -a database.default.php database.php
cp -a core.default.php core.php
cp -a config.default.php config.php
sed -i "s#3306#${DBPORT}#" database.php
sed -i "s#'host' => 'localhost'#'host' => '$DBHOST'#" database.php
sed -i "s#db login#$DBUSER_MISP#" database.php
sed -i "s#db password#$DBPASSWORD_MISP#" database.php
sed -i "s#'database' => 'misp'#'database' => '$DBNAME'#" database.php
sed -i "s#Rooraenietu8Eeyo<Qu2eeNfterd-dd+#$(random_string)#" config.php
print_ok "MISP php config files moved and configured."

# Generate ssl certificate
if [ -z "${PATH_TO_SSL_CERT}" ]; then
    print_notification "Generating self-signed SSL certificate."
    sudo openssl req -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=${OPENSSL_C}/ST=${OPENSSL_ST}/L=${OPENSSL_L}/O=${OPENSSL_O}/OU=${OPENSSL_OU}/CN=${OPENSSL_CN}/emailAddress=${OPENSSL_EMAILADDRESS}" \
    -keyout /etc/ssl/private/misp.local.key -out /etc/ssl/private/misp.local.crt &>> $logfile
    error_check "Self-signed SSL certificate generation"
else
    print_status "Using provided SSL certificate."
fi

# Generate misp-ssl.conf
print_status "Creating Apache configuration file for MISP..."

  echo "<VirtualHost _default_:80>
          ServerAdmin admin@$MISP_DOMAIN
          ServerName $MISP_DOMAIN

          Redirect permanent / https://$MISP_DOMAIN

          LogLevel warn
          ErrorLog /var/log/apache2/misp.local_error.log
          CustomLog /var/log/apache2/misp.local_access.log combined
          ServerSignature Off
  </VirtualHost>

  <VirtualHost _default_:443>
          ServerAdmin admin@$MISP_DOMAIN
          ServerName $MISP_DOMAIN
          DocumentRoot $MISP_PATH/app/webroot

          <Directory $MISP_PATH/app/webroot>
                  Options -Indexes
                  AllowOverride all
  		            Require all granted
                  Order allow,deny
                  allow from all
          </Directory>

          SSLEngine On
          SSLCertificateFile /etc/ssl/private/misp.local.crt
          SSLCertificateKeyFile /etc/ssl/private/misp.local.key

          LogLevel warn
          ErrorLog /var/log/apache2/misp.local_error.log
          CustomLog /var/log/apache2/misp.local_access.log combined
          ServerSignature Off
          Header set X-Content-Type-Options nosniff
          Header set X-Frame-Options DENY
  </VirtualHost>" | sudo tee /etc/apache2/sites-available/misp-ssl.conf  &>> $logfile

error_check "Apache configuration file creation"  &>> $logfile

print_status "Setting up Python environment for MISP"

sudo -u $MISP_USER virtualenv -p python3 ${PATH_TO_MISP}/venv &>> /var/log/misp_install.log \
    && . ${PATH_TO_MISP}/venv/bin/activate &>> /var/log/misp_install.log \
    && ${PATH_TO_MISP}/venv/bin/pip install -r ${PATH_TO_MISP}/requirements.txt &>> /var/log/misp_install.log
# Create a python3 virtualenv
sudo -u ${APACHE_USER} virtualenv -p python3 ${MISP_PATH}/venv &>> $logfile
error_check "Python virtualenv creation"
#
cd ${MISP_PATH}
. ./venv/bin/activate &>> $logfile
error_check "Python virtualenv activation"

# install python dependencies
${MISP_PATH}/venv/bin/pip install -r ${MISP_PATH}/requirements.txt  &>> $logfile
error_check "Python dependencies installation"
#
chown -R ${APACHE_USER}:${APACHE_USER} ${MISP_PATH}/venv
#
  # Enable modules, settings, and default of SSL in Apache
  sudo a2dismod status &>> $logfile
  sudo a2enmod ssl &>> $logfile
  sudo a2enmod rewrite &>> $logfile
  sudo a2enmod headers &>> $logfile
  sudo a2dissite 000-default &>> $logfile
  sudo a2ensite default-ssl &>> $logfile

  # activate new vhost
  sudo a2dissite default-ssl &>> $logfile
  sudo a2ensite misp-ssl &>> $logfile

print_status "Finalising MISP setup..."
sudo chown -R ${APACHE_USER}:${APACHE_USER} ${MISP_PATH} &>> $logfile
sudo chown -R ${APACHE_USER}:${APACHE_USER} ${MISP_PATH}/.git &>> $logfile
sudo chmod -R 750 ${MISP_PATH} &>> $logfile
sudo chmod -R g+ws ${MISP_PATH}/app/tmp &>> $logfile
sudo chmod -R g+ws ${MISP_PATH}/app/files &>> $logfile
sudo chmod -R g+ws ${MISP_PATH}/app/files/scripts/tmp &>> $logfile
