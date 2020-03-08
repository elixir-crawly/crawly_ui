FROM elixir:1.8.2-alpine

RUN apk update && apk upgrade \
               && apk add bash nodejs nodejs-npm git \
               && npm install npm webpack -g --no-progress

# Add local node module binaries to PATH
ENV PATH=./node_modules/.bin:$PATH


ADD . /crawlyui
WORKDIR /crawlyui

RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && MIX_ENV=dev mix compile \
    && cd assets && npm install -D && cd ..
