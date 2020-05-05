FROM elixir:1.10.3-alpine

RUN apk update && apk upgrade \
               && apk add bash nodejs nodejs-npm git \
               && npm install npm webpack -g --no-progress

# Add local node module binaries to PATH
ENV PATH=./node_modules/.bin:$PATH

ADD . /shops
WORKDIR /shops

RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && MIX_ENV=dev mix compile
