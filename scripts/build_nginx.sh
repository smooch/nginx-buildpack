#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

# Latest stable & mainline versions, as of Nov 17th, 2016: stable: 1.10.2  mainline: 1.11.6
NGINX_VERSION=${NGINX_VERSION-1.11.6}
PCRE_VERSION=${PCRE_VERSION-8.39}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.32}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://ftp.exim.llorien.org/pcre/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/agentzh/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

echo "Downloading $headers_more_nginx_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-http_realip_module \
		--with-http_sub_module \
		--with-pcre=pcre-${PCRE_VERSION} \
		--with-http_stub_status_module \
		--prefix=/tmp/nginx \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION}
	make install
)

cp /tmp/nginx/sbin/nginx $1
