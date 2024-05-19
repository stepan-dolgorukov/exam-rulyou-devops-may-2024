#!/usr/bin/env bash

host_certbot='192.168.57.5'
pattern_certificate='*.rulyou.ru.pem'

targets=(
  '192.168.57.5'
)

mkdir certificates

for certificate in $(ssh root@${host_certbot} find /etc/ssl -name "${pattern_certificate}");
do
  rsync root@${host_certbot}:"${certificate}" ./certificates/
done

for host in "${targets[@]}";
do

  containers=$(ssh root@"${host}" docker container list --quiet)
  rsync --recursive certificates root@"${host}":'~'

  for container in ${containers}; do

    ssh root@"${host}" docker exec "${container}" mkdir --parent /etc/ssl

    for certificate in $(ssh root@"${host}" find '~/certificates' -type f);
    do
      echo "${host}:${container}:${certificate}"
      ssh root@"${host}" docker cp "${certificate}" "${container}":/etc/ssl
    done

  done

  ssh root@"${host}" rm --recursive '~/certificates'
done