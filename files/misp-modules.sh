# Install MISP-Modules:
# https://misp.github.io/misp-modules/install/
apt-get install -y git libpq5 libjpeg-dev tesseract-ocr libpoppler-cpp-dev imagemagick virtualenv libopencv-dev zbar-tools libzbar0 libzbar-dev libfuzzy-dev libcaca-dev
cd /usr/local/src/
chmod 2775 /usr/local/src
git clone https://github.com/MISP/misp-modules.git
git clone https://github.com/stricaud/faup.git
git clone https://github.com/stricaud/gtcaca.git
#
# Install gtcaca/faup
cd gtcaca && mkdir -p build && cd build && cmake .. && make && sudo make install
cd ../../faup && mkdir -p build && cd build && cmake .. && make && sudo make install
ldconfig
cd ../../misp-modules
chown -R www-data:www-data /usr/local/src
sudo -E -H -u www-data /var/www/MISP/venv/bin/pip install -I -r REQUIREMENTS
sudo -E -Hu www-data /var/www/MISP/venv/bin/pip install .
#
# Enable CLAMAV Scan for Vírus:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_clamav_enabled" "true"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_clamav_connection" "unix:///var/run/clamav/clamd.ctl"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.attachment_scan_module" "clamav"
#
# Enable Workflow, Action and Enrichment Modules: ( Only Enable if MISP Modules is Enabled before )
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_services_enable" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Action_services_enable" true
