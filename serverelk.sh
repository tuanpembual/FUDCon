#!/bin/bash
## base on 
# [0] https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-centos-7
# [1] https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-centos-7

echo "192.168.98.101 localhost" >> /etc/hosts
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
rpm -ivh $(pwd)/package/jre-8u101-linux-x64.rpm
rpm -ivh $(pwd)/package/elasticsearch-2.4.0.rpm
rpm -ivh $(pwd)/package/kibana-4.6.1-x86_64.rpm
rpm -ivh $(pwd)/package/logrotate-3.9.2-5.fc24.x86_64.rpm
rpm -ivh $(pwd)/package/logstash-2.4.0.noarch.rpm
#rpm -ivh $(pwd)/package/filebeat-1.3.1-x86_64.rpm
#rpm -ivh $(pwd)/package/topbeat-1.3.1-x86_64.rpm

## setup env

# ES
systemctl enable elasticsearch.service
sed -i '54s/.*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch.service

# Kibana
sed -i '5s/.*/server.host: "localhost"/' /opt/kibana/config/kibana.yml
systemctl enable kibana.service
systemctl start kibana.service

# nginx
dnf install nginx unzip vim httpd-tools -y
sed -i.bak -e '38,88d' /etc/nginx/nginx.conf
cp $(pwd)/conf/kibana.conf /etc/nginx/conf.d/kibana.conf
systemctl enable nginx.service
systemctl start nginx.service

# Logstash
mkdir -p /etc/pki/tls/certs
mkdir -p /etc/pki/tls/private
sed -i '253s/.*/subjectAltName = IP: 192.168.98.101/' /etc/pki/tls/openssl.cnf
cd /etc/pki/tls;openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
cd /vagrant

# Configure Logstash
cat <<EOT > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
EOT

cat <<EOT > /etc/logstash/conf.d/10-syslog-filter.conf
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOT

cat <<EOT > /etc/logstash/conf.d/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOT
systemctl restart logstash
chkconfig logstash on

# Load Kibana Dashboards
cd /vagrant/package
unzip beats-dashboards-*.zip
cd beats-dashboards-*
./load.sh

# Load template
cd /vagrant/package
curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json
curl -XPUT 'http://localhost:9200/_template/topbeat?pretty' -d@topbeat.template.json

# # Config filebeat and topbeat
# cat <<EOT > /etc/filebeat/filebeat.yml
# ############################# Filebeat ######################################
# filebeat:
#   prospectors:
#     -
#       paths:
#         - /var/log/syslog

#       input_type: sylog

#       document_type: development

#   registry_file: /var/lib/filebeat/registry
# output:

#   logstash:
#     hosts: ["192.168.98.101:5044"]
#     bulk_max_size: 1024

#     tls:
#       certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]

# shipper:

# logging:
#   files:
#     rotateeverybytes: 10485760 # = 10MB

# #######
# EOT

# cat <<EOT > /etc/topbeat/topbeat.yml
# ################### Topbeat Configuration Example #########################
# input:
#   period: 10
#   procs: [".*"]
#   stats:
#     system: true
#     process: true
#     filesystem: true
#     cpu_per_core: true

# output:

#   logstash:
#     hosts: ["192.168.98.101:5044"]
#     #bulk_max_size: 2048

#     tls:
#       certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]

# shipper:

# logging:
#   files:
#     rotateeverybytes: 10485760 # = 10MB

# #######
# EOT

# systemctl enable filebeat
# systemctl start filebeat
# systemctl enable topbeat
# systemctl start topbeat

###

cat /etc/pki/tls/certs/logstash-forwarder.crt
