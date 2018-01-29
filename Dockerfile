FROM scardon/ruby-node-alpine:2.5

COPY rootfs /

RUN apk --update add \
  g++ make \
  # PostgreSQL dependencies
  postgresql-client postgresql-dev \
  # Nokogiri dependencies
  libxml2 libxslt libxml2-dev libxslt-dev
