#!/bin/sh
/usr/sbin/sshd
mysqld_safe --skip-grant-tables &
sleep 3
su postgres -c "pg_ctl start -D /var/lib/postgresql/data -l /tmp/pg.log" 2>/dev/null
redis-server --protected-mode no --daemonize yes
sleep infinity
