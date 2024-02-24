FROM alpine:edge AS build
RUN apk add --no-cache --update go gcc g++
WORKDIR /app
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -o lep-api

FROM alpine:edge
ARG STRONGBOX_KEY
ENV STRONGBOX_KEY=$STRONGBOX_KEY

ARG STRONGBOX_KEYRING
ENV STRONGBOX_KEYRING=$STRONGBOX_KEYRING

WORKDIR /app

ENV STRONGBOX_HOME=/app
RUN echo $STRONGBOX_KEYRING > /app/.strongbox_keyring
RUN echo $STRONGBOX_KEYRING > $HOME/.strongbox_keyring

ENV GOPATH=/go CGO_ENABLED=0
RUN PATH=$PATH:$GOPATH/bin

RUN apk add --no-cache --update go gcc g++
RUN apk add --no-cache sqlite

COPY --from=build /app/lep-api /app/lep-api
COPY --from=build /app/laufendentdeckendb.db /app/laufendentdeckendb.db

RUN if [ -z "$STRONGBOX_KEY" ]; then echo "Already decrypted"; else go install github.com/uw-labs/strongbox@v1.1.0; fi
RUN if [ -z "$STRONGBOX_KEY" ]; then echo "Already decrypted"; else /go/bin/strongbox -decrypt -key $STRONGBOX_KEY /app/laufendentdeckendb.db; fi

ENTRYPOINT /app/lep-api
