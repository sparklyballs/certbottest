# package versions
ARG FAIL2BAN_BRANCH="0.11"
ARG IGBINARY_VER="3.0.1"
ARG MCRYPT_VER="1.0.2"
ARG MEMCACHED_VER="3.1.3"
ARG NGINX_VER="1.15.9"
ARG PHP_VER="7.3.3"
ARG PYTHON_VER="3.7.2"
ARG PYTHON_PIP_VERSION="19.0.3"

# alpine base version
ARG ALPINE_VER="3.9"
FROM sparklyballs/alpine-test:${ALPINE_VER}

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

######## nginx section ##########
ARG NGINX_VER

# set workdir
WORKDIR /usr/src/nginx

# add nginx user
RUN \
	addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	\
# install build packages	
	\
	&& apk add --no-cache --virtual=nginx_build \
		curl \
		gcc \
		gd-dev \
		geoip-dev \
		gnupg1 \
		libc-dev \
		libxslt-dev \
		linux-headers \
		make \
		openssl-dev \
		pcre-dev \
		perl-dev \
		zlib-dev \
	\
# fetch source
	\
	&& mkdir -p \
		/usr/src/nginx \
	&& curl -o \
	/tmp/nginx.tar.gz -L \
	"https://nginx.org/download/nginx-${NGINX_VER}.tar.gz" \
	&& tar xf \
	/tmp/nginx.tar.gz -C \
	/usr/src/nginx --strip-components=1 \
	\
# set config options
	\
	&& NGINX_CONF=( \
	--"conf-path=/etc/nginx/nginx.conf" \
	--"error-log-path=/var/log/nginx/error.log" \
	--"group=nginx" \
	--"http-client-body-temp-path=/var/cache/nginx/client_temp" \
	--"http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp" \
	--"http-log-path=/var/log/nginx/access.log" \
	--"http-proxy-temp-path=/var/cache/nginx/proxy_temp" \
	--"http-scgi-temp-path=/var/cache/nginx/scgi_temp" \
	--"http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp" \
	--"lock-path=/var/run/nginx.lock" \
	--"modules-path=/usr/lib/nginx/modules" \
	--"pid-path=/var/run/nginx.pid" \
	--"prefix=/etc/nginx" \
	--"sbin-path=/usr/sbin/nginx" \
	--"user=nginx" \
	--with-compat \
	--with-file-aio \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--"with-http_geoip_module=dynamic" \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--"with-http_image_filter_module=dynamic" \
	--with-http_mp4_module \
	--"with-http_perl_module=dynamic" \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--"with-http_xslt_module=dynamic" \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--"with-stream_geoip_module=dynamic" \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-threads \
	) \
	\
# build package
	\
	&& ./configure "${NGINX_CONF[@]}" --with-debug \
	&& make -j"$(getconf _NPROCESSORS_ONLN)" \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure "${NGINX_CONF[@]}" \
	&& make -j"$(getconf _NPROCESSORS_ONLN)" \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	\
# strip packages
	\
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	\
# install envsubst
	\
	&& apk add --no-cache gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
# install runtime packages
	\
	&& NGINX_RUNDEPS_VAR="$(scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
		| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
		| sort -u \
		| xargs -r apk info --installed \
		| sort -u \
	)" \
	&& declare NGINX_RUNDEPS_ARR \
	&& eval "NGINX_RUNDEPS_ARR=($NGINX_RUNDEPS_VAR)" \
	&& apk add --no-cache "${NGINX_RUNDEPS_ARR[@]}" \
	\
# strip packages
	\
	&& for dirs in bin lib; \
	do \
		find /usr/"${dirs}" -type f | \
		while read -r files ; do strip "${files}" || true \
		; done \
	; done \
	\
# cleanup
	\
	&& apk del --purge \
		gettext \
		nginx_build \
	&& mv /tmp/envsubst /usr/local/bin/ \
	&& rm -rf \
		/tmp/* \
		/usr/src/* \
		/root \
	&& mkdir -p \
		/root		
	
######## php section ##########
ARG IGBINARY_VER
ARG MCRYPT_VER
ARG MEMCACHED_VER
ARG PHP_VER

# build environment variables
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c
ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_URL="https://secure.php.net/get/php-${PHP_VER}.tar.xz/from/this/mirror"

# set workdir
WORKDIR /usr/src/php

# copy php build files
COPY php_build_files/* /usr/local/bin/

# add www-data user
RUN \
	addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data \
	\
# create folders
	\
	&& mkdir -p \
		"$PHP_INI_DIR/conf.d" \
		/var/www/html \
	&& chown www-data:www-data /var/www/html \
	&& chmod 777 /var/www/html \
	\
# install build packages
	\
	&& apk add --no-cache --virtual=php_build \
		$PHPIZE_DEPS \
		argon2-dev \
		bzip2-dev \
		coreutils \
		curl \
		curl-dev \
		freetype-dev \
		icu-dev \
		libedit-dev \
		libjpeg-turbo-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libpng-dev \
		libsodium-dev \
		libxml2-dev \
		libxpm-dev \
		libzip-dev \
		openssl-dev \
		postgresql-dev \
		sqlite-dev \
# fetch source
	\
	&& set -ex \
	&& curl -o \
	/usr/src/php.tar.xz -L \
	"$PHP_URL" \
	\
# build package
	\
	&& export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-exif=shared \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--enable-option-checking=fatal \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--with-curl \
		--with-libedit \
		--with-mhash \
		--with-openssl \
		--with-password-argon2 \
		--with-sodium=shared \
		--with-zlib \
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j"$(nproc)" \
	&& find . -type f -name '*.a' -delete \
	&& make install \
	\
# install additional php packages
	\
	&& docker-php-ext-install -j"$(nproc)" bz2 \
	&& docker-php-ext-configure gd \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j"$(nproc)" gd \
	&& docker-php-ext-install -j"$(nproc)" intl \
	&& docker-php-ext-install -j"$(nproc)" mysqli \
	&& docker-php-ext-install -j"$(nproc)" pdo_mysql \
	&& docker-php-ext-install -j"$(nproc)" pdo_pgsql \
	&& docker-php-ext-install -j"$(nproc)" pgsql \
	&& docker-php-ext-install -j"$(nproc)" soap \
	&& docker-php-ext-install -j"$(nproc)" sockets \
	&& docker-php-ext-install -j"$(nproc)" zip \
	\
# install pecl packages
	\
	&& pecl install "igbinary-${IGBINARY_VER}" \
	&& pecl install "mcrypt-${MCRYPT_VER}" \
	&& pecl install "memcached-${MEMCACHED_VER}" \
# strip packages
	\
	&& { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	\
# copy init files
	\
	&& cp -v php.ini-production "$PHP_INI_DIR/php.ini" \
	&& docker-php-source delete \
	\
# enable additional php extensions
	&& docker-php-ext-enable \
		exif \
		gd \
		igbinary \
		mcrypt \
		memcached \
		opcache \
		sodium \
	\
# install runtime packages
	\
	&& PHP_RUNDEPS_VAR="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& declare PHP_RUNDEPS_ARR \
	&& eval "PHP_RUNDEPS_ARR=($PHP_RUNDEPS_VAR)" \
	&& apk add --no-cache "${PHP_RUNDEPS_ARR[@]}" \
	\
# strip packages
	\
	&& for dirs in local/bin local/lib; \
	do \
		find /usr/"${dirs}" -type f | \
		while read -r files ; do strip "${files}" || true \
		; done \
	; done \
	\
# cleanup
	\
	&& apk del --purge \
		php_build \
	&& rm -rf \
		/tmp/* \
		/usr/local/lib/php/build \
		/usr/src/* \
		/root \
	&& mkdir -p \
		/root

######## python section ##########

ARG FAIL2BAN_BRANCH
ARG PYTHON_VER
ARG PYTHON_PIP_VERSION

# environment settings
ENV LANG C.UTF-8
ENV PATH /usr/local/bin:$PATH

# set workdir
WORKDIR /usr/src/python

# install build packages
RUN \
	apk add --no-cache --virtual=python_build \
		bzip2-dev \
		coreutils \
		curl \
		dpkg-dev dpkg \
		expat-dev \
		findutils \
		gcc \
		gdbm-dev \
		libc-dev \
		libffi-dev \
		libnsl-dev \
		libtirpc-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl-dev \
		pax-utils \
		readline-dev \
		sqlite-dev \
		tcl-dev \
		tk \
		tk-dev \
		util-linux-dev \
		xz-dev \
		zlib-dev \
	\
# fetch source
	\
	&& mkdir -p \
		/usr/src/python \
	&& curl -o \
	/tmp/python.tar.xz -L \
	"https://www.python.org/ftp/python/${PYTHON_VER%%[a-z]*}/Python-${PYTHON_VER}.tar.xz" \
	&& tar xf \
	/tmp/python.tar.xz -C \
	/usr/src/python --strip-components=1 \
	\
# build package
	\
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--without-ensurepip \
		--with-system-expat \
		--with-system-ffi \
	&& make -j "$(nproc)" \
	EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
	&& make install \
	\
# build fail2ban package
	\
	&& mkdir -p \
		/tmp/fail2ban-src \
	&& curl -o \
	/tmp/fail2ban.tar.gz -L \
	"https://github.com/fail2ban/fail2ban/archive/${FAIL2BAN_BRANCH}.tar.gz" \
	&& tar xf \
	/tmp/fail2ban.tar.gz -C \
	/tmp/fail2ban-src --strip-components=1 \
	&& cd /tmp/fail2ban-src \
	&& python3 setup.py install \
	\
# install runtime packages
	\
	&& find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		| xargs -rt apk add --no-cache --virtual .python_rundeps \
	\
# symlinks that are expected to exist
	\
	&& ln -s /usr/local/bin/idle3 /usr/local/bin/idle \
	&& ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc \
	&& ln -s /usr/local/bin/python3 /usr/local/bin/python \
	&& ln -s /usr/local/bin/python3-config /usr/local/bin/python-config \
	\
# install pip
	\
	&& curl -o /tmp/get-pip.py 'https://bootstrap.pypa.io/get-pip.py' \
	&& python /tmp/get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==${PYTHON_PIP_VERSION}" \
	\
# install pip packages
	&& pip install -U \
	certbot-dns-cloudflare \
	certbot-dns-cloudxns \
	certbot-dns-digitalocean \
	certbot-dns-dnsimple \
	certbot-dns-dnsmadeeasy \
	certbot-dns-google \
	certbot-dns-luadns \
	certbot-dns-nsone \
	certbot-dns-ovh \
	certbot-dns-rfc2136 \
	certbot-dns-route53 \
	requests \
# strip packages
	\
	&& PYTHON_MAJOR="${PYTHON_VER%.*}" \
	&& for dirs in local/lib/python$PYTHON_MAJOR; \
	do \
		find /usr/"${dirs}" -type f | \
		while read -r files ; do strip "${files}" || true \
		; done \
	; done \
	\
# install runtime packages
	\
	&& apk add --no-cache \
		ip6tables \
		iptables \
		logrotate \
	\
# cleanup
	\
	&& pip --version \
	&& find /usr/local -depth \
		\( \
		\( -type d -a \( -name test -o -name tests \) \) \
		-o \
		\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& apk del --purge \
		python_build \
	&& rm -rf \
		/tmp/* \
		/usr/src/* \
		/root \
	&& mkdir -p \
		/root
