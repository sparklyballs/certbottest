# php package versions
ARG IGBINARY_VER="3.0.1"
ARG MCRYPT_VER="1.0.2"
ARG MEMCACHED_VER="3.1.3"
ARG PHP_VER="7.3.3"

# nginx package versions
ARG NGINX_VER="1.16.0"

# python package versions
ARG PYTHON_VER="3.7.3"

# alpine base version
ARG ALPINE_VER="3.9"
FROM sparklyballs/alpine-test:${ALPINE_VER} as fetch_stage

############## fetch stage ##############

# environment variables
ARG NGINX_VER
ARG PYTHON_VER

# install fetch packages
RUN \
	apk add --no-cache \
		bash \
		curl \
		xz

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch source code
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		/usr/src/fail2ban \
		/usr/src/nginx/nginx-core \
		/usr/src/nginx/nginx-module-cache-purge \
		/usr/src/nginx/nginx-module-echo \
		/usr/src/nginx/nginx-module-fancyindex \
		/usr/src/nginx/nginx-module-headers-more \
		/usr/src/nginx/nginx-module-lua \
		/usr/src/nginx/nginx-module-lua-upstream \
		/usr/src/nginx/nginx-module-nchan \
		/usr/src/nginx/nginx-module-ngx-dev \
		/usr/src/nginx/nginx-module-redis \
		/usr/src/nginx/nginx-module-upload-progress \
		/usr/src/python \
	&& curl -o \
		/tmp/fail2ban.tar.gz -L \
		"https://github.com/fail2ban/fail2ban/archive/${FAIL2BAN_COMMIT}.tar.gz" \
	&& curl -o \
		/tmp/nginx.tar.gz -L \
		"https://nginx.org/download/nginx-${NGINX_VER}.tar.gz" \
	&& curl -o \
		nginx-cache-purge.tar.gz -L \
		"https://github.com/nginx-modules/ngx_cache_purge/archive/${NGINX_CACHE_PURGE_RELEASE}.tar.gz" \
	&& curl -o \
		nginx-echo.tar.gz -L \
		"https://github.com/openresty/echo-nginx-module/archive/${NGINX_ECHO_COMMIT}.tar.gz" \
	&& curl -o \
		nginx-fancyindex.tar.gz -L \
		"https://github.com/aperezdc/ngx-fancyindex/archive/${NGINX_FANCYINDEX_COMMIT}.tar.gz" \
	&& curl -o \
		nginx-headers-more.tar.gz -L \
		"https://github.com/openresty/headers-more-nginx-module/archive/${NGINX_HEADERS_MORE_COMMIT}.tar.gz" \
	&& curl -o \
		nginx_lua.tar.gz -L \
		"https://github.com/openresty/lua-nginx-module/archive/${NGINX_LUA_COMMIT}.tar.gz" \
	&& curl -o \
		nginx_lua_upstream.tar.gz -L \
		"https://github.com/openresty/lua-upstream-nginx-module/archive/${NGINX_LUA_UPSTREAM_COMMIT}.tar.gz" \
	&& curl -o \
		nginx-nchan.tar.gz -L \
		"https://github.com/slact/nchan/archive/v${NGINX_NCHAN_TAG}.tar.gz" \
	&& curl -o \
		nginx-ngx-dev.tar.gz -L \
		"https://github.com/simplresty/ngx_devel_kit/archive/v${NGINX_NGX_DEVEL_RELEASE}.tar.gz" \
	&& curl -o \
		nginx-redis.tar.gz -L \
		"https://github.com/openresty/redis2-nginx-module/archive/${NGINX_REDIS_COMMIT}.tar.gz" \
	&& curl -o \
		nginx_upload_prog.tar.gz -L \
		"https://github.com/masterzen/nginx-upload-progress-module/archive/${NGINX_UPLOAD_COMMIT}.tar.gz" \
	&& curl -o \
		python.tar.xz -L \
		"https://www.python.org/ftp/python/${PYTHON_VER%%[a-z]*}/Python-${PYTHON_VER}.tar.xz" \
	&& tar xf \
		/tmp/fail2ban.tar.gz -C \
		/usr/src/fail2ban --strip-components=1 \
	&& tar xf \
		/tmp/nginx.tar.gz -C \
		/usr/src/nginx/nginx-core --strip-components=1 \
	&& tar xf \
		nginx-cache-purge.tar.gz -C \
		/usr/src/nginx/nginx-module-cache-purge --strip-components=1 \
	&& tar xf \
		nginx-echo.tar.gz -C \
		/usr/src/nginx/nginx-module-echo --strip-components=1 \
	&& tar xf \
		nginx-fancyindex.tar.gz -C \
		/usr/src/nginx/nginx-module-fancyindex --strip-components=1 \
	&& tar xf \
		nginx-headers-more.tar.gz -C \
		/usr/src/nginx/nginx-module-headers-more --strip-components=1 \
	&& tar xf \
		nginx_lua.tar.gz -C \
		/usr/src/nginx/nginx-module-lua --strip-components=1 \
	&& tar xf \
		nginx_lua_upstream.tar.gz -C \
		/usr/src/nginx/nginx-module-lua-upstream --strip-components=1 \
	&& tar xf \
		nginx-nchan.tar.gz -C \
		/usr/src/nginx/nginx-module-nchan --strip-components=1 \
	&& tar xf \
		nginx-ngx-dev.tar.gz -C \
		/usr/src/nginx/nginx-module-ngx-dev --strip-components=1 \
	&& tar xf \
		nginx-redis.tar.gz -C \
		/usr/src/nginx/nginx-module-redis --strip-components=1 \
	&& tar xf \
		nginx_upload_prog.tar.gz -C \
		/usr/src/nginx/nginx-module-upload-progress --strip-components=1 \
	&& tar xf \
		python.tar.xz -C \
		/usr/src/python --strip-components=1

FROM sparklyballs/alpine-test:${ALPINE_VER} as nginx_build

############## nginx build stage ##############

# copy artifacts fetch stage
COPY --from=fetch_stage /usr/src/nginx/ /usr/src/nginx/

# install build packages
RUN \
		apk add --no-cache \
		bash \
		ca-certificates \
		gcc \
		gd-dev \
		geoip-dev \
		gnupg1 \
		libc-dev \
		libxml2-dev \
		libxslt-dev \
		linux-headers \
		luajit-dev \
		make \
		openssl-dev \
		paxmark \
		pcre-dev \
		perl-dev \
		pkgconf \
		zlib-dev

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set workdir
WORKDIR /usr/src/nginx/nginx-core

# build package
RUN \
	LUAJIT_INC="$(pkgconf --variable=includedir luajit)" \
	&& LUAJIT_LIB="$(pkgconf --variable=libdir luajit)" \
	&& export LUAJIT_INC \
	&& export LUAJIT_LIB \
	&& set -ex \
	&& ./configure \
		--add-dynamic-module=/usr/src/nginx/nginx-module-cache-purge \
		--add-dynamic-module=/usr/src/nginx/nginx-module-echo \
		--add-dynamic-module=/usr/src/nginx/nginx-module-fancyindex \
		--add-dynamic-module=/usr/src/nginx/nginx-module-headers-more \
		--add-dynamic-module=/usr/src/nginx/nginx-module-lua \
		--add-dynamic-module=/usr/src/nginx/nginx-module-lua-upstream \
		--add-dynamic-module=/usr/src/nginx/nginx-module-nchan \
		--add-dynamic-module=/usr/src/nginx/nginx-module-ngx-dev \
		--add-dynamic-module=/usr/src/nginx/nginx-module-redis \
		--add-dynamic-module=/usr/src/nginx/nginx-module-upload-progress \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--group=nginx \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-log-path=/var/log/nginx/access.log \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp\
		--lock-path=/var/run/nginx.lock \
		--modules-path=/usr/lib/nginx/modules \
		--pid-path=/var/run/nginx.pid \
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--user=nginx \
		--with-compat \
		--with-file-aio \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_dav_module \
		--with-http_degradation_module \
		--with-http_flv_module \
		--with-http_geoip_module=dynamic \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_image_filter_module=dynamic \
		--with-http_mp4_module \
		--with-http_perl_module=dynamic \
		--with-http_random_index_module \
		--with-http_realip_module \
		--with-http_secure_link_module \
		--with-http_slice_module \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-http_sub_module \
		--with-http_v2_module \
		--with-http_xslt_module=dynamic \
		--with-mail \
		--with-mail_ssl_module \
		--with-stream \
		--with-stream_geoip_module=dynamic \
		--with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-threads \
	&& make -j"$(getconf _NPROCESSORS_ONLN)" \
	&& make DESTDIR=/build/nginx install \
	&& rm -rf /build/nginx/etc/nginx/html/ \
	&& mkdir /build/nginx/etc/nginx/conf.d/ \
	&& mkdir -p /build/nginx/usr/share/nginx/html/ \
	&& install -m644 html/index.html /build/nginx/usr/share/nginx/html/ \
	&& install -m644 html/50x.html /build/nginx/usr/share/nginx/html/

# install envsubst
RUN \
	mkdir -p \
		/build/nginx/bin \
	&& apk add --no-cache \
		gettext \
	&& mv /usr/bin/envsubst /build/nginx/bin/

# determine runtime packages
RUN \
	set -ex \
	&& nginx_deps="$( \
		scanelf --needed --nobanner /build/nginx/usr/sbin/nginx /build/nginx/usr/lib/nginx/modules/*.so /build/nginx/bin/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& printf "%s" "$nginx_deps" > /build/runtime-packages \
	&& echo -en "\n" >> /build/runtime-packages

FROM sparklyballs/alpine-test:${ALPINE_VER} as python_build

############## python build stage ##############

# copy artifacts fetch and nginx build stages
COPY --from=fetch_stage /usr/src/python /usr/src/python
COPY --from=nginx_build /build/runtime-packages /build/runtime-packages

# install build packages
RUN \
	apk add --no-cache \
		bash \
		bzip2-dev \
		coreutils \
		curl \
		dpkg-dev \
		dpkg \
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
		zlib-dev

# set workdir
WORKDIR /usr/src/python

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# build package
RUN \
	set -ex \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
	&& make -j "$(nproc)" \
	EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
	&& make -j "$(nproc)" DESTDIR=/build/python install

# determine runtime packages
RUN \
	set -ex \
	&& python_deps="$(find /build/python/usr/local -type f \
		-executable -not \( -name '*tkinter*' \) \
		-exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /build/python/usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& printf "%s" "$python_deps" >> /build/python-packages \
	&& printf "%s" "$python_deps" >> /build/runtime-packages \
	&& echo -en "\n" >> /build/runtime-packages \
	&& sed -i "/libpython/d" /build/python-packages \
	&& sed -i "/libpython/d" /build/runtime-packages

FROM sparklyballs/alpine-test:${ALPINE_VER} as python_packages

# copy artifacts fetch, and python build stages
COPY --from=fetch_stage /usr/src/fail2ban /usr/src/fail2ban
COPY --from=python_build /build/python/ /
COPY --from=python_build /build/python-packages /build/python-packages

# install python deps
RUN \
	set -ex \
	&& while read -r line; \
		do apk add --no-cache "$line"; \
	done < /build/python-packages

# install build packages
RUN \
	apk add --no-cache \
		curl \
		gcc \
		libffi-dev \
		linux-headers \
		musl-dev \
		openssl-dev

# install pip packages
RUN \
	pip3 install \
	--no-warn-script-location \
	--prefix=/build/certbot  \
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
		requests

# set workdir
WORKDIR /usr/src/fail2ban

# install fail2ban
RUN \
	set -ex \
	&& python3 setup.py install --root /build/fail2ban
	

FROM sparklyballs/alpine-test:${ALPINE_VER} as strip_stage

############## strip stage ##############

# copy artifacts build stages
COPY --from=nginx_build /build/nginx/ /build/all/
COPY --from=python_build /build/runtime-packages /build/all/
COPY --from=python_build /build/python/ /build/all/
COPY --from=python_packages /build/certbot/bin/ /build/all/bin/
COPY --from=python_packages /build/certbot/lib/ /build/all/usr/local/lib/
COPY --from=python_packages /build/fail2ban/ /build/all/

# sort runtime packages
RUN \
	set -ex \
	&& sort -u -o /build/all/runtime-packages /build/all/runtime-packages

# install strip packages
RUN \
	apk add --no-cache \
		bash \
		binutils

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# strip packages
RUN \
	set -ex \
	&& strip /build/all/usr/sbin/nginx* \
	&& strip /build/all/usr/lib/nginx/modules/*.so \
	&& find /build/all/usr/local/lib -type f | \
		while read -r files ; do strip "${files}" || true \
	; done \
	&& find /build/all/usr/local -depth \
		\( \
		\( -type d -a \( -name test -o -name tests \) \) \
		-o \
		\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + \
	&& rm -rf \
		/build/all/etc/nginx/koi-* \
		/build/all/etc/nginx/win-utf

FROM sparklyballs/alpine-test:${ALPINE_VER}

############## runtime stage ##############

# copy artifacts strip stage
COPY --from=strip_stage /build/all/ /

# environment settings
ENV DHLEVEL=2048 ONLY_SUBDOMAINS=false AWS_CONFIG_FILE=/config/dns-conf/route53.ini
ENV LANG C.UTF-8
ENV PATH /usr/local/bin:$PATH
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# add users for packages
RUN \
	addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	\
# create symlinks
	\
	&& ln -s /usr/lib/nginx/modules /etc/nginx/modules \
	&& ln -s /usr/local/bin/pip3 /usr/local/bin/pip \
	&& ln -s /usr/local/bin/idle3 /usr/local/bin/idle \
	&& ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc \
	&& ln -s /usr/local/bin/python3 /usr/local/bin/python \
	&& ln -s /usr/local/bin/python3-config /usr/local/bin/python-config \
	\
# install runtime packages
	\
	&& apk add --no-cache \
		apache2-utils \
		binutils \
		curl \
		git \
		logrotate \
		openssl \
	&& set -ex \
	&& while read -r line; \
		do apk add --no-cache "$line"; \
	done < /runtime-packages

