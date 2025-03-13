FROM ubuntu:24.04

# Sharif-Judge Image Name
ARG SHJ_NAME
# Sharif-Judge Base URI
ARG SHJ_URI
# smtp server
ARG SMTP_HOST
# MariaDB Data & Volume
ARG MARIA_DATADIR=/var/lib/mysql
ARG MARIA_VOLUME
# Sharif-Judge Datadir
ARG SHJ_DATADIR=/var/shjdata
ARG SHJ_VOLUME

# to ENV
ENV SHJ_NAME=${SHJ_NAME}
ENV SHJ_URI=${SHJ_URI}
ENV SMTP_HOST=${SMTP_HOST}
ENV MARIA_DATADIR=${MARIA_DATADIR}
ENV SHJ_DATADIR=${SHJ_DATADIR}

# package install
RUN apt-get update && \
    apt-get install -y vim nano git apache2 php php-mysql libapache2-mod-php mariadb-server gcc g++ openjdk-21-jdk python3-all && \
    rm -rf /var/lib/apt/lists/*

# make MariaDB init script
RUN echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'judgedb';" > /tmp/mysql-init && \
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'judgedb' WITH GRANT OPTION;" >> /tmp/mysql-init && \
    echo "FLUSH PRIVILEGES;" >> /tmp/mysql-init && \ 
    echo "CREATE DATABASE sharif;" >> /tmp/mysql-init

# Sharif-Judge Settings
RUN rm -rf /var/www/html && \
    git clone https://github.com/sanoakr/Sharif-Judge-Docker.git /var/www/html && \
    chown -R www-data:www-data /var/www && \
    # smtp server
    sed -i -e "s|public \$smtp_host\s*=\s*'';|public \$smtp_host = '${SMTP_HOST}';|" /var/www/html/system/libraries/Email.php && \
    # tester & assignments
    sed -i -e "s|'shj_value' => '/var/shjdata/tester'|'shj_value' => '${SHJ_DATADIR}/tester'|" /var/www/html/application/controllers/Install.php && \
    sed -i -e "s|'shj_value' => '/var/shjdata/assignments'|'shj_value' => '${SHJ_DATADIR}/assignments'|" /var/www/html/application/controllers/Install.php && \
    # base URI
    sed -i -e "s|\$config\['base_url'\]\s*=\s*'';|\$config['base_url'] = '${SHJ_URI}';|" /var/www/html/application/config/config.php && \
    # Title
    sed -i -e "s|<h1 class=\"shjlogo-text\">Sharif <span>Judge</span></h1>|<h1 class=\"shjlogo-text\">Sharif <span>Judge</span> for ${SHJ_NAME}</h1>|" /var/www/html/application/views/templates/top_bar.twig && \
    chmod 755 /var/www/html/application/cache/Twig

# make startup script
RUN echo "#!/bin/bash" > /start.sh && \
    # copy Sharif-Judge tester & assignments datadir
    echo "mkdir -p ${SHJ_DATADIR}" >> start.sh && \
    echo "if [ ! -d ${SHJ_DATADIR}/tester ]; then cp -r /var/www/html/tester ${SHJ_DATADIR}/; fi" >> /start.sh && \
    echo "if [ ! -d ${SHJ_DATADIR}/assignments ]; then cp -r /var/www/html/assignments ${SHJ_DATADIR}/; fi" >> / start.sh && \
    echo "chown -R www-data:www-data /var/shjdata" >> /start.sh && \
    # initi database
    echo "mkdir -p /run/mysqld; chown -R mysql:mysql /run/mysqld" >> /start.sh && \
    echo "if [ -d ${MARIA_DATADIR}/mysql ]; then chown -R mysql:mysql ${MARIA_DATADIR}; mariadb-install-db  --user=mysql --datadir=${MARIA_DATADIR}; fi" >> /start.sh && \
    echo "if [ -f /tmp/mysql-init ]; then mysqld --init-file=/tmp/mysql-init --user=mysql &" >> /start.sh && \
    echo "sleep 10; mysqladmin --silent --wait=30 ping || exit 1" >> /start.sh && \
    echo "rm -f /tmp/mysql-init; fi" >> /start.sh && \
    # Start Servers
    echo "mysqld_safe --user=mysql &" >> /start.sh && \
    echo "mysqladmin --silent --wait=30 ping || exit 1" >> /start.sh && \
    echo "apache2 -D FOREGROUND" >> /start.sh && \
    chmod +x /start.sh

# http port
EXPOSE 80

# Apache env
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_PID_FILE=/var/run/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    LANG=C

# Set startup script
CMD ["/start.sh"]
