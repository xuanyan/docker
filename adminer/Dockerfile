FROM php:8.3.30-cli-alpine3.22

WORKDIR /app

RUN docker-php-ext-install mysqli \
    && curl -L -o /app/adminer.php https://www.adminer.org/latest-mysql.php

COPY index.php /app/index.php
COPY adminer-plugins /app/adminer-plugins

RUN echo "<?php return [];" > /app/databases.php

COPY adminer-plugins.php /app/adminer-plugins.php

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app"]
