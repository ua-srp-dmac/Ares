FROM dmac/r-base:latest

# envsubst for templating Apache config with env vars at startup
RUN apt-get update && apt-get install -y --no-install-recommends gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Create mod_auth_openidc session cache directory
RUN mkdir -p /var/cache/apache2/mod_auth_openidc \
    && chown www-data:www-data /var/cache/apache2/mod_auth_openidc

# Copy Ares R scripts
COPY AresMaster.r /var/www/Rfiles/AresMaster.r
COPY AresDevelop.r /var/www/Rfiles/AresDevelop.r

# Static assets (Semantic UI, jQuery, logos)
COPY Rconstants/ /var/www/Ares/Rconstants/

# About pages
COPY About/ /var/www/html/Ares/

# Apache config template (env vars substituted at runtime)
COPY apache-ares.conf /etc/apache2/sites-available/ares.conf.template
RUN a2dissite 000-default

# Entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8080

CMD ["/docker-entrypoint.sh"]
