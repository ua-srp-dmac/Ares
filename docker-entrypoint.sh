#!/bin/bash
set -e

# Ensure rapache (mod_R) is loaded
if [ ! -f /etc/apache2/conf-enabled/Rapache.conf ]; then
    echo "LoadModule R_module /usr/lib/apache2/modules/mod_R.so" \
        > /etc/apache2/conf-available/Rapache.conf
    a2enconf Rapache > /dev/null 2>&1
fi

# Substitute OIDC env vars into Apache config
envsubst '${OIDC_CLIENT_ID} ${OIDC_CLIENT_SECRET} ${OIDC_CRYPTO_PASSPHRASE}' \
    < /etc/apache2/sites-available/ares.conf.template \
    > /etc/apache2/sites-available/ares.conf

# Enable the site
a2ensite ares > /dev/null 2>&1

# Start Apache in foreground
exec apachectl -D FOREGROUND
