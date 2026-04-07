FROM ruby:3.4-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    build-essential \
    pkg-config \
    libpq-dev \
    postgresql-client \
    redis-tools \
    imagemagick \
    file \
    shared-mime-info \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN gem install bundler -v 2.6.4 && \
    bundle _2.6.4_ config set without 'development test' && \
    bundle _2.6.4_ config set path '/usr/local/bundle' && \
    bundle _2.6.4_ install --jobs 4 --retry 3

COPY entrypoint.sh /entrypoint.sh
COPY start-discourse.sh /start-discourse.sh

RUN chmod +x /entrypoint.sh /start-discourse.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start-discourse.sh"]
