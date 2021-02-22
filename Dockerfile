FROM ruby:2.7.2-alpine
RUN apk add --no-cache \
    gcc \
    git \
    linux-headers \
    make \
    musl-dev

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock rom-dynamodb.gemspec ./
COPY lib/rom/dynamodb/version.rb ./lib/rom/dynamodb/version.rb

RUN bundle install

COPY . ./

CMD ["rspec"]