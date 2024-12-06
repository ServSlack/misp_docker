#!/bin/bash
cd /var/www/MISP
git pull origin 2.5
git submodule update
cd /var/www/MISP/app/files/scripts/cti-python-stix2
sudo -H -u www-data /var/www/MISP/venv/bin/pip install .
chown -R www-data:www-data /var/www/MISP/
chmod -R 750 /var/www/MISP/app/Config/
