FROM ruby:2.5.1
MAINTAINER Colin Mitchell <colin@muffinlabs.com>

ENV GOPHER_ADDRESS localhost
ENV GOPHER_PORT 70

EXPOSE $GOPHER_PORT

RUN mkdir /app 
WORKDIR /app

COPY . /app

RUN bundle install

#CMD ["/app/bin/gopher2000", "/app/examples/simple.rb"]

