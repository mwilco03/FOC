#!/bin/sh
/usr/sbin/sshd
smbd -D
nmbd -D
vsftpd /etc/vsftpd/vsftpd.conf &
sleep infinity
