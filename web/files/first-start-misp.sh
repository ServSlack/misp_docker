#!/bin/bash
echo " FIRT START MISP_WEB "
#
# ZeroMQ settings:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_enable" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_host" "127.0.0.1"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_port" 50000
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_redis_host" "127.0.0.1"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_redis_port" 6379
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_redis_database" 1
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_redis_namespace" "mispq"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_event_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_object_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_object_reference_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_attribute_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_sighting_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_user_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_organisation_notifications_enable" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_include_attachments" false
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_tag_notifications_enable" false
#
# SimpleBackGroundJobs:
# https://github.com/MISP/MISP/blob/2.4/docs/background-jobs-migration-guide.md
#
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.enabled" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.redis_host" localhost
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.redis_port" 6379
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.redis_database" 1
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.redis_namespace" background_jobs
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.max_job_history_ttl" 86400
sleep 1 && sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.supervisor_host" localhost
sleep 1 && sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.supervisor_port" 9001
sleep 2 && sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.supervisor_user" supervisor
sleep 2 && sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.supervisor_password" supervisor
sleep 2 && sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "SimpleBackgroundJobs.redis_serializer" JSON
#
# Update MISP - All in one Shoot
cd $PATH_TO_MISP
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateMISP
#
# Update MISP Database:
sudo -E -Hu www-data /var/www/MISP/app/Console/cake Admin runUpdates
#
sudo -E -Hu www-data /var/www/MISP/app/Console/cake Admin updateJSON
# Configure MISP Security settings:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.disable_browser_cache" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.check_sec_fetch_site_header" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.csp_enforce" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.advanced_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.do_not_log_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.username_in_response_header" true
#
# MISP Security settings;
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.disable_browser_cache" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.check_sec_fetch_site_header" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.csp_enforce" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.advanced_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.do_not_log_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.username_in_response_header" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.encryption_key" "${SECURITY_ENCRYPTION_KEY}"
#
# Disable OTP Authentication to Prevent Problems ( " After if need fill free to enable it " )
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.otp_required" false
#
#
# Disable E-mail Alert:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.disable_emailing" true --force
#
# Principal Security / Audit:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.log_user_ips" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.log_new_audit" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.log_user_ips" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.log_client_ip" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.log_user_ips_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.advanced_authkeys" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.alert_on_suspicious_logins" true
#
# Enable Workflow, Action and Enrichment Modules: ( Only Enable if MISP Modules is Enabled before )
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_services_enable" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Action_services_enable" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Workflow_enable" true
#
# Enable Import x Export Modules
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Import_services_enable" true
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Export_services_enable" true
#
#Configure GPG MISP:
#sudo chown -R www-data:www-data /var/www/MISP/.gnupg
#sudo chmod 700 /var/www/MISP/.gnupg
#sudo find /var/www/MISP/.gnupg -type f -exec chmod 600 {} \;
#sudo find /var/www/MISP/.gnupg -type d -exec chmod 700 {} \;
#
sudo -u www-data gpg --homedir $PATH_TO_MISP/.gnupg --quick-generate-key --batch --passphrase "$GPG_PASSPHRASE" "$GPG_EMAIL_ADDRESS" ed25519 sign never
sudo -u www-data sh -c "gpg --homedir $PATH_TO_MISP/.gnupg --export --armor $GPG_EMAIL_ADDRESS" | $SUDO_WWW tee $PATH_TO_MISP/app/webroot/gpg.asc
#
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.email" "${GPG_EMAIL_ADDRESS}"
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.homedir" "${PATH_TO_MISP}/.gnupg"
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.password" "${GPG_PASSPHRASE}"
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.obscure_subject" true
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.key_fetching_disabled" false
${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "GnuPG.binary" "$(which gpg)"
#
# Change CLAMD necessary features:
sed -i 's/^Foreground false/Foreground true/g' /etc/clamav/clamd.conf
sed -i 's/^MaxThreads 12/MaxThreads 15/g' /etc/clamav/clamd.conf
sed -i 's/^MaxEmbeddedPE 10M/MaxEmbeddedPE 20M/g' /etc/clamav/clamd.conf
sed -i 's/^IdleTimeout 30/IdleTimeout 120/g' /etc/clamav/clamd.conf
sed -i 's/^CommandReadTimeout 5/CommandReadTimeout 30/g' /etc/clamav/clamd.conf
sed -i 's/^SendBufTimeout 200/SendBufTimeout 300/g' /etc/clamav/clamd.conf
echo "TCPSocket 3310 " >> /etc/clamav/clamd.conf
service clamav-freshclam no-daemon
supervisorctl start clamd
supervisorctl status clamd
#
# Enable CLAMAV Scan for Vírus:
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_clamav_enabled" "true"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_clamav_connection" "unix:///var/run/clamav/clamd.ctl"
sudo -Hu www-data /var/www/MISP/app/Console/cake Admin setSetting "MISP.attachment_scan_module" "clamav"
#
# Remove Temporary files about MISP installation.
#rm -rf /tmp/*
