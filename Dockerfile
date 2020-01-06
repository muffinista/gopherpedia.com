FROM ruby:2.7-slim
MAINTAINER Colin Mitchell <colin@muffinlabs.com>

ARG BUNDLER_VERSION=1.17.3

ENV APP_HOME /app
ENV BUNDLE_PATH /usr/local/bundle

ENV LANG=C.UTF-8

RUN apt-get update -qq && apt-get install -qq --no-install-recommends \
    locales \
    build-essential \
    mariadb-client \
    libmariadbclient-dev \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${BUNDLE_PATH}
RUN gem install bundler -v ${BUNDLER_VERSION}

ADD Gemfile ${APP_HOME}/Gemfile
ADD Gemfile.lock ${APP_HOME}/Gemfile.lock

WORKDIR $APP_HOME

RUN bundle check || bundle install
ADD . /app

ENV GOPHER_HOST 0.0.0.0
ENV GOPHER_PORT 7070
EXPOSE $GOPHER_PORT

CMD ["bundle", "exec", "gopher2000", "gopherpedia.rb"]

