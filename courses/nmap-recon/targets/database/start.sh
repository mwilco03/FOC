#!/bin/sh
/usr/sbin/sshd
mysqld_safe --skip-grant-tables &
su postgres -c "pg_ctl start -D /var/lib/postgresql/data -l /var/log/postgresql.log" &
redis-server --protected-mode no --daemonize yes
sleep infinity
