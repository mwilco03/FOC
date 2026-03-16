FROM python:3.11-alpine

RUN apk add --no-cache \
    nginx openssh mariadb mariadb-client \
    curl net-tools bash

# SSH on 22
RUN ssh-keygen -A && \
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config && \
    adduser -D webadmin && echo "webadmin:W3bS3rv3r!" | chpasswd
RUN echo "Corporate Web Server - Authorized Access Only" > /etc/ssh/banner

# Nginx on 80 + 8888
COPY nginx-default.conf /etc/nginx/http.d/default.conf
RUN mkdir -p /var/www/html/admin /var/www/html/dev /run/nginx
COPY index.html /var/www/html/index.html
COPY admin.html /var/www/html/admin/index.html
COPY phpinfo.html /var/www/html/dev/index.html

# MariaDB on 3306 — bind to all interfaces
RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1 && \
    sed -i '/skip-networking/d' /etc/my.cnf.d/mariadb-server.cnf && \
    printf '[mysqld]\nbind-address=0.0.0.0\n' > /etc/my.cnf.d/bind.cnf

# JWT challenge app on port 3000
COPY jwt_server.py /app/jwt_server.py

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh /app/jwt_server.py
RUN chmod +x /start.sh

EXPOSE 22 80 3000 3306 8888
CMD ["/start.sh"]
