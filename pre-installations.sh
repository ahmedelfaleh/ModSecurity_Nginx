#!/bin/bash

yum install apt-utils autoconf automake git libtool wget zlib1g-dev gcc-c++-4.8.5-39.el7.x86_64 yajl-devel.x86_64 GeoIP-devel.x86_64 lmdb-devel.x86_64 ssdeep-devel.x86_64 lua-devel.x86_64 libcurl-devel.x86_64 libxml2-devel.x86_64 pcre-devel.x86_64 -y
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
make install
