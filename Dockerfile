FROM nginx:mainline-alpine
MAINTAINER Neo Ighodaro <hi@neo.ng>

ENV php_conf /etc/php7/php.ini
ENV fpm_conf /etc/php7/php-fpm.d/www.conf
ENV composer_hash 669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410

################## INSTALLATION STARTS ##################

RUN echo @testing http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    sed -i -e "s/v3.4/edge/" /etc/apk/repositories && \
    echo /etc/apk/respositories && \
    apk update && \
    apk add --no-cache bash \
    openssh-client \
    wget \
    nginx \
    supervisor \
    curl \
    git \
    php7-fpm \
    php7-pdo \
    php7-pdo_mysql \
    php7-mysqlnd \
    php7-mysqli \
    php7-mcrypt \
    php7-mbstring \
    php7-ctype \
    php7-zlib \
    php7-gd \
    php7-exif \
    php7-intl \
    php7-sqlite3 \
    php7-xml \
    php7-curl \
    php7-openssl \
    php7-iconv \
    php7-json \
    php7-phar \
    php7-zip \
    php7-session \
    dialog &&\
    mkdir -p /etc/nginx && \
    mkdir -p /run/nginx && \
    mkdir -p /etc/nginx/sites-available && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /var/log/supervisor && \
    rm -Rf /var/www/* && \
    rm -Rf /etc/nginx/nginx.conf && \
    php7 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php7 -r "if (hash_file('SHA384', 'composer-setup.php') === '${composer_hash}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php7 composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php7 -r "unlink('composer-setup.php');" && \
    ln -s /usr/bin/php7 /usr/bin/php

##################  INSTALLATION ENDS  ##################

##################  CONFIGURATION STARTS  ##################

ADD start.sh /start.sh
ADD conf/supervisord.conf /etc/supervisord.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf

RUN chmod 755 /start.sh && \
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
    sed -i \
        -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
        -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" \
        -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" \
        -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
        ${php_conf} && \
    sed -i \
        -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 4/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = nobody/user = nginx/g" \
        -e "s/group = nobody/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = nobody/listen.owner = nginx/g" \
        -e "s/;listen.group = nobody/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf} && \
    ln -s /etc/php7/php.ini /etc/php7/conf.d/php.ini && \
    find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

##################  CONFIGURATION ENDS  ##################

EXPOSE 443 80

WORKDIR /var/www

CMD ["/start.sh"]
