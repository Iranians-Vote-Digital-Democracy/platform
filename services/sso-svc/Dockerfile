FROM golang:1.22-alpine AS buildbase

RUN apk add git

WORKDIR /go/src/github.com/jomhoor/sso-svc
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /usr/local/bin/sso-svc .


FROM alpine:3.20

COPY --from=buildbase /usr/local/bin/sso-svc /usr/local/bin/sso-svc
COPY config.yaml /config.yaml
RUN apk add --no-cache ca-certificates

ENTRYPOINT ["sso-svc"]
