FROM alpine:3.7

COPY rootfs /

### Ruby bit ###
# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
  echo 'install: --no-document'; \
  echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_BIN="$GEM_HOME/bin" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
  && chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

ENV RUBY_MAJOR 2.5
ENV RUBY_VERSION 2.5.0
ENV RUBY_DOWNLOAD_SHA256 1da0afed833a0dab94075221a615c14487b05d0c407f991c8080d576d985b49b

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -ex \
  \
  && apk add --no-cache --virtual .ruby-builddeps \
  autoconf \
  bison \
  bzip2 \
  bzip2-dev \
  ca-certificates \
  coreutils \
  gcc \
  gdbm-dev \
  glib-dev \
  libc-dev \
  libffi-dev \
  libxml2-dev \
  libxslt-dev \
  linux-headers \
  make \
  ncurses-dev \
  libressl \
  libressl-dev \
  procps \
  readline-dev \
  ruby \
  tar \
  yaml-dev \
  zlib-dev \
  xz \
  \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
  \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  \
  && cd /usr/src/ruby \
  \
  # hack in "ENABLE_PATH_CHECK" disabling to suppress:
  #   warning: Insecure world writable dir
  && { \
  echo '#define ENABLE_PATH_CHECK 0'; \
  echo; \
  cat file.c; \
  } > file.c.new \
  && mv file.c.new file.c \
  \
  && autoconf \
  # the configure script does not detect isnan/isinf as macros
  && ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
  ./configure --disable-install-doc --enable-shared \
  && make -j"$(getconf _NPROCESSORS_ONLN)" \
  && make install \
  \
  && runDeps="$( \
  scanelf --needed --nobanner --recursive /usr/local \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --virtual .ruby-rundeps $runDeps \
  bzip2 \
  ca-certificates \
  libffi-dev \
  libressl-dev \
  yaml-dev \
  procps \
  zlib-dev \
  && apk del .ruby-builddeps \
  && cd / \
  && rm -r /usr/src/ruby

ENV RUBYGEMS_VERSION 2.7.4
RUN gem update --system "$RUBYGEMS_VERSION"

ENV BUNDLER_VERSION 1.16.1
RUN gem install bundler --version "$BUNDLER_VERSION"

RUN apk update && apk add nodejs curl bash gnupg
RUN npm install -g yarn
