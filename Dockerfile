# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

ARG BUNDLER_VERSION=2.6.3

ENV APP_HOME=/app

ENV LANG=C.UTF-8
ENV BUNDLE_PATH=/app/vendor/bundle BUNDLE_FROZEN=1 BUNDLE_CLEAN=1 BUNDLE_RETRY=3 BUNDLE_JOBS=4

RUN apt-get update -qq && \
    apt-get install -qq --no-install-recommends \
    locales \
    build-essential \
    mariadb-client \
    restic \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && \
    gem install bundler -v ${BUNDLER_VERSION}
   

# Copy in freedesktop.org.xml which is required for mimemagic
RUN mkdir -p /usr/share/mime/packages/
COPY freedesktop.org.xml /usr/share/mime/packages/freedesktop.org.xml


WORKDIR $APP_HOME
COPY Gemfile Gemfile.lock ./

RUN bundle install

ADD . $APP_HOME

ENV GOPHER_HOST=0.0.0.0
ENV GOPHER_PORT=7070
EXPOSE $GOPHER_PORT

CMD ["bundle", "exec", "gopher2000", "gopherpedia.rb"]

