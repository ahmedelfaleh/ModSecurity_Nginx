#!/bin/bash

# Install Prerequisite Packages
yum install apt-utils autoconf automake git libtool wget zlib1g-dev gcc-c++-4.8.5-39.el7.x86_64 yajl-devel.x86_64 GeoIP-devel.x86_64 lmdb-devel.x86_64 ssdeep-devel.x86_64 lua-devel.x86_64 libcurl-devel.x86_64 libxml2-devel.x86_64 pcre-devel.x86_64 -y

# Download and Compile the ModSecurity 3.0 Source Code
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install

# Download the NGINX Connector for ModSecurity and Compile It as a Dynamic Module
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

nginx -v > nginx.txt

if [ -s nginx.txt ]
then
v=$(cat nginx.txt | cut -d"/" -f2)
else
nginx -v 2> nginx.txt
v=$(cat nginx.txt | cut -d"/" -f2)
fi

wget http://nginx.org/download/nginx-$v.tar.gz
tar zxvf nginx-$v.tar.gz

cd nginx-$v

./configure --with-compat --add-dynamic-module=../ModSecurity-nginx

make modules

cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

sed -i '5i load_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

mkdir /etc/nginx/modsec

wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended

mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf

sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

cat << 'EOF' >> /etc/nginx/modsec/main.conf

# From https://github.com/SpiderLabs/ModSecurity/blob/master/
# modsecurity.conf-recommended
#
# Edit to set SecRuleEngine On
Include "/etc/nginx/modsec/modsecurity.conf"

# Basic test rule
SecRule ARGS:testparam "@contains test" "id:1234,deny,status:403"

EOF

read -p 'Enter the config file name, please. Example: /etc/nginx/conf.d/YOUR-FILENAME.conf' config
sed -i '5i \   \ modsecurity on; modsecurity_rules_file /etc/nginx/modsec/main.conf;' $config

cp -a unicode.mapping /etc/ngins/modsec/

systemctl enable nginx
systemctl start nginx

firewall-cmd --add-service=http --permanent
firewall-cmd --reload


