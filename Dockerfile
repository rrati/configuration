# Build the manager binary
FROM golang:1.13.3-alpine3.10 as builder

RUN apk add --update --no-cache git bash
WORKDIR /workspace
# Copy the jsonnet source
COPY environments/operator/ environments/operator/
COPY components/ components/
COPY jsonnetfile.json jsonnetfile.json
# Build
RUN GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
RUN jb install
RUN GO111MODULE="on" go get github.com/brancz/locutus

FROM alpine:3.10 as runner
WORKDIR /
COPY --from=builder /go/bin/locutus /
COPY --from=builder /workspace/environments/operator /environments/operator
COPY --from=builder /workspace/components/ /components/
COPY --from=builder /workspace/vendor/ /vendor/
RUN chgrp -R 0 /vendor && chmod -R g=u /vendor
RUN chgrp -R 0 /environments && chmod -R g=u /environments
RUN chgrp -R 0 /components && chmod -R g=u /components

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ARG DOCKERFILE_PATH
ARG VCS_BRANCH

LABEL vendor="Observatorium" \
    name="observatorium/observatorium-operator" \
    description="Observatorium Operator" \
    io.k8s.display-name="observatorium/observatorium-operator" \
    io.k8s.description="Observatorium Operator" \
    maintainer="Observatorium <team-monitoring@redhat.com>" \
    version="$VERSION" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.description="Observatorium Operator" \
    org.label-schema.docker.cmd="docker run --rm observatorium/observatorium-operator" \
    org.label-schema.docker.dockerfile=$DOCKERFILE_PATH \
    org.label-schema.name="observatorium/observatorium-operator" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-branch=$VCS_BRANCH \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/observatorium/configuration" \
    org.label-schema.vendor="observatorium/observatorium-operator" \
    org.label-schema.version=$VERSION

ENTRYPOINT ["/locutus", "--renderer=jsonnet", "--renderer.jsonnet.entrypoint=environments/operator/main.jsonnet", "--trigger=resource", "--trigger.resource.config=environments/operator/config.yaml"]
