#!/bin/bash

#mkdir -p /etc/pki/tls/certs
#cp $(pwd)/conf/logstash-forwarder.crt /etc/pki/tls/certs/

rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
rpm -ivh $(pwd)/package/filebeat-1.3.1-x86_64.rpm
rpm -ivh $(pwd)/package/topbeat-1.3.1-x86_64.rpm

# Config filebeat and topbeat
cat <<EOT > /etc/filebeat/filebeat.yml
############################# Filebeat ######################################
filebeat:
  prospectors:
    -
      paths:
        - /var/log/syslog
        - /var/log/nginx/access.log
        - /var/log/nginx/error.log

      input_type: sylog

      document_type: development

  registry_file: /var/lib/filebeat/registry
output:

  logstash:
    hosts: ["192.168.98.101:5044"]
    bulk_max_size: 1024

    tls:
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB

#######
EOT

cat <<EOT > /etc/topbeat/topbeat.yml
################### Topbeat Configuration Example #########################
input:
  period: 10
  procs: [".*"]
  stats:
    system: true
    process: true
    filesystem: true
    cpu_per_core: true

output:

  logstash:
    hosts: ["192.168.98.101:5044"]
    #bulk_max_size: 2048

    tls:
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB

#######
EOT

systemctl enable filebeat
systemctl start filebeat
systemctl enable topbeat
systemctl start topbeat

