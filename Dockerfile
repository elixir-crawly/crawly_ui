FROM elixir:1.10.3-alpine

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
    && MIX_ENV=prod mix compile \
    && cd assets && npm install -D && cd .. \
    && npm run deploy --prefix ./assets \
    && mix phx.digest \
    && MIX_ENV=prod mix release ec

FROM elixir:1.10.3-alpine
COPY --from=0 /crawlyui/_build/prod/rel/ec/ /crawlyui

RUN apk update && apk upgrade && apk add bash
WORKDIR /crawlyui

EXPOSE 4000
CMD /crawlyui/ec/bin/ec start
