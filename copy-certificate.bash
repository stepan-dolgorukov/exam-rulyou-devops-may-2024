#!/usr/bin/env bash

host_certbot='192.168.57.5'
pattern_certificate='*.rulyou.ru.pem'

mkdir certificates

for certificate in $(ssh root@${host_certbot} find /etc/ssl -name ${pattern_certificate});
do
  rsync root@${host_certbot}:${certificate} ./certificates/
done