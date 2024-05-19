#!/usr/bin/env bash

host_certbot='192.168.57.5'
pattern_certificate='*.rulyou.ru.pem'
catalog_certificates='/etc/ssl/certs'

targets=(
  '192.168.57.5'
)

mkdir certificates

for certificate in $(ssh root@${host_certbot} find ${catalog_certificates} -name "${pattern_certificate}");
do
  rsync root@${host_certbot}:"${certificate}" ./certificates/
done

for host in "${targets[@]}";
do

  containers=$(ssh root@"${host}" docker container list --quiet)
  rsync --recursive certificates root@"${host}":'~'

  for container in ${containers}; do

    ssh root@"${host}" docker exec "${container}" mkdir --parent ${catalog_certificates}
    ssh root@"${host}" docker cp "${container}":"${catalog_certificates}" certificates_"${container}"

    for certificate in $(ssh root@"${host}" find '~/certificates' -type f);
    do
      certificate_base=$(basename ${certificate})

      answer=$(ssh root@"${host}" diff \
        '~/certificates'/"${certificate_base}" \
        '~/certificates_'"${container}/${certificate_base}" \
        2>/dev/null >/dev/null && \
        echo '1' || echo '0')

      if [ "${answer}" = '0' ]; then
        echo "${host}:${container}:${certificate_base}"
        ssh root@"${host}" docker cp "${certificate}" "${container}":${catalog_certificates}
      fi
    done

    ssh root@"${host}" rm -r certificates_"${container}"
  done

  ssh root@"${host}" rm --recursive '~/certificates'
done