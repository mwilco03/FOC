#!/bin/bash
# CACHE entrypoint

set -e

# Start Redis (no auth - vulnerable)
redis-server /etc/redis/redis.conf --daemonize yes

# Start OpenSSH (for redis user callback after RCE)
rc-service sshd start

# Initialize and start PostgreSQL (decoy)
if [ ! -d "/var/lib/postgresql/16/data" ]; then
    su - postgres -c "initdb -D /var/lib/postgresql/16/data"
    su - postgres -c "echo \"host all all 0.0.0.0/0 md5\" >> /var/lib/postgresql/16/data/pg_hba.conf"
fi
rc-service postgresql start

echo "CACHE container started"
echo "Services: Redis no-auth (6379), SSH (22), PostgreSQL decoy (5432)"

# Keep container alive
exec tail -f /dev/null
