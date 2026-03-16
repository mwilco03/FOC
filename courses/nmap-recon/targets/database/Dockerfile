FROM python:3.11-alpine

RUN apk add --no-cache openssh mariadb mariadb-client postgresql redis bash net-tools

# SSH on 22
RUN ssh-keygen -A && \
    adduser -D dbadmin && echo "dbadmin:Db@dmin2024" | chpasswd

# MariaDB on 3306
RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1

# PostgreSQL on 5432
RUN mkdir -p /run/postgresql /var/lib/postgresql/data && \
    chown -R postgres:postgres /run/postgresql /var/lib/postgresql && \
    su postgres -c "initdb -D /var/lib/postgresql/data" > /dev/null 2>&1
RUN echo "listen_addresses = '*'" >> /var/lib/postgresql/data/postgresql.conf && \
    echo "host all all 0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf

# Redis on 6379 - no auth

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh
RUN chmod +x /start.sh

EXPOSE 22 3306 5432 6379
CMD ["/start.sh"]
