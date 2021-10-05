FROM ruby:3.0.2-alpine3.14

ENV BUILD_PACKAGES="curl-dev ruby-dev build-base" \
    DEV_PACKAGES="zlib-dev libxml2-dev libxslt-dev tzdata yaml-dev sqlite-dev" \
    RUBY_PACKAGES="ruby-json yaml"

# Update and install base packages and nokogiri gem that requires a
# native compilation
RUN apk update && \
    apk upgrade && \
    apk add --no-cache --update\
    $BUILD_PACKAGES \
    $DEV_PACKAGES \
    $RUBY_PACKAGES && \
    mkdir -p /usr/src/myapp

# Copy the app into the working directory. This assumes your Gemfile
# is in the root directory and includes your version of Rails that you
# want to run.
WORKDIR /usr/src/myapp
COPY Gemfile ./
COPY Gemfile.lock ./

RUN gem install bundler
RUN bundle config build.nokogiri --use-system-libraries && \
    bundle install --jobs=4 --retry=10

# Copy the source files. If the application is referenced with git url, it can run without volume mount.
COPY . ./

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
