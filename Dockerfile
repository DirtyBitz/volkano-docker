FROM scardon/ruby-node-alpine:2.5

RUN apk --update add \
  g++ make \
  # PostgreSQL dependencies
  postgresql-client postgresql-dev \
  # Nokogiri dependencies
  libxml2 libxslt libxml2-dev libxslt-dev

RUN gem install bundler --force

COPY rootfs /
