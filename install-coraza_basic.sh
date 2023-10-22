#!/bin/bash
# Coraza-spoa installer by Thelogh
#AUTOMATIC INSTALLATION SCRIPT WITH BASIC CORAZA-SPOA CONFIGURATION FOR HAPROXY ON UBUNTU SERVER 22.04
#https://www.alldiscoveries.com/installation-and-configuration-haproxy-v2-4-22-with-waf-coraza-spoa-on-ubuntu-server-22-04-lts/
#For all requests write on the blog
#REPOSITORY
#https://github.com/thelogh/haproxy-coraza
#V.1.0.0
#

systemctl stop unattended-upgrades.service

apt-get update -y

apt-get upgrade -y

apt-get install pkg-config make gcc -y

apt-get install git -y

snap install go --classic

git clone https://github.com/corazawaf/coraza-spoa.git

cd ./coraza-spoa

#START THE COMPILATION
make

#CREATE THE USERS AND THE GROUP
addgroup --quiet --system coraza-spoa
adduser --quiet --system --ingroup coraza-spoa --no-create-home --home /nonexistent --disabled-password coraza-spoa


#CREATE THE CONFIGURATION DIRECTORY
mkdir -p /etc/coraza-spoa

#CREATE THE LOG DIRECTORY
mkdir -p /var/log/coraza-spoa /var/log/coraza-spoa/audit

#I CREATE EMPTY LOGS
touch /var/log/coraza-spoa/server.log /var/log/coraza-spoa/error.log \
        /var/log/coraza-spoa/audit.log /var/log/coraza-spoa/debug.log

cp -a ./coraza-spoa_amd64 /usr/bin/coraza-spoa

chmod 755 /usr/bin/coraza-spoa

#COPY THE SPOA CONFIGURATION FILE



(cat << EOF

# The SPOA server bind address
bind: 127.0.0.1:9000

# Process request and response with this application if provided app name is not found.
# You can remove or comment out this config param if you don't need "default_application" functionality.
default_application: haproxy_waf

applications:
  haproxy_waf:
    # Get the coraza.conf from https://github.com/corazawaf/coraza
    #
    # Download the OWASP CRS from https://github.com/coreruleset/coreruleset/releases
    # and copy crs-setup.conf & the rules, plugins directories to /etc/coraza-spoa
    directives: |
      Include /etc/coraza-spoa/coraza.conf
      Include /etc/coraza-spoa/crs-setup.conf
      Include /etc/coraza-spoa/plugins/*-config.conf
      Include /etc/coraza-spoa/plugins/*-before.conf
      Include /etc/coraza-spoa/rules/*.conf
      Include /etc/coraza-spoa/plugins/*-after.conf

    # HAProxy configured to send requests only, that means no cache required
    # NOTE: there are still some memory & caching issues, so use this with care
    no_response_check: true

    # The transaction cache lifetime in milliseconds (60000ms = 60s)
    transaction_ttl_ms: 60000
    # The maximum number of transactions which can be cached
    transaction_active_limit: 100000

    # The log level configuration, one of: debug/info/warn/error/panic/fatal
    log_level: info
    # The log file path
    log_file: /var/log/coraza-spoa/coraza-agent.log
EOF
) > /etc/coraza-spoa/config.yaml


#COPY THE CONFIGURATION FILE OF THE RECOMMENDED CORAZA SERVICE
wget https://raw.githubusercontent.com/corazawaf/coraza/main/coraza.conf-recommended -O /etc/coraza-spoa/coraza.conf

#ENABLE THE RULES
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/coraza-spoa/coraza.conf

#I COPY THE RULES

mkdir -p ./coraza-crs

cd ./coraza-crs

git clone https://github.com/coreruleset/coreruleset

cp ./coreruleset/crs-setup.conf.example /etc/coraza-spoa/crs-setup.conf
cp -R ./coreruleset/rules /etc/coraza-spoa
cp -R ./coreruleset/plugins /etc/coraza-spoa

cd ..


#CONFIGURE PERMISSIONS
chown -R coraza-spoa:coraza-spoa /etc/coraza-spoa/
chmod 700 /etc/coraza-spoa
chmod -R 600 /etc/coraza-spoa/*
chmod 700 /etc/coraza-spoa/rules
chmod 700 /etc/coraza-spoa/plugins

#SERVICE CONFIGURATION
cp -a ./contrib/coraza-spoa.service /lib/systemd/system/coraza-spoa.service 
systemctl daemon-reload
systemctl enable coraza-spoa.service 

#INSTALLATION AND CONFIGURATION HAPROXY

apt-get install haproxy -y


#CONFIGURATION FILE SPOA
cp -a ./doc/config/coraza.cfg /etc/haproxy/coraza.cfg

#CHANGE THE CONFIGURATION WITH THE NAME OF THE APP
sed -i 's/app=str(sample_app) id=unique-id src-ip=src/app=str(haproxy_waf) id=unique-id src-ip=src/' /etc/haproxy/coraza.cfg

sed -i 's/app=str(sample_app) id=unique-id version=res.ver/app=str(haproxy_waf) id=unique-id version=res.ver/' /etc/haproxy/coraza.cfg
#ADD THE END OF LINE CHARACTER TO AVOID HAPROXY ERROR
sed -i 's|event on-http-response|event on-http-response\n|' /etc/haproxy/coraza.cfg

#RENAME THE HAPROXY CONFIGURATION FILE AND COPY THE NEW ONE
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_orig
cp -a ./doc/config/haproxy.cfg /etc/haproxy/haproxy.cfg
#ADD THE END OF LINE CHARACTER TO AVOID HAPROXY ERROR
sed -i -e '$a\' /etc/haproxy/haproxy.cfg

#CONFIGURE PERMISSIONS
chown haproxy /etc/haproxy/coraza.cfg
chmod 600 /etc/haproxy/coraza.cfg

#START SERVICE
systemctl stop haproxy
systemctl start coraza-spoa
systemctl start haproxy
