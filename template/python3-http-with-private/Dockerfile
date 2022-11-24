FROM --platform=${TARGETPLATFORM:-linux/amd64} ghcr.io/openfaas/of-watchdog:0.9.10 as watchdog
FROM --platform=${TARGETPLATFORM:-linux/amd64} python:3.9-alpine as build

ENV APP_ROOT=/home/app

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /usr/bin/fwatchdog /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
SHELL ["/bin/sh", "-eo", "pipefail", "-c"]

ARG ADDITIONAL_PACKAGE
# Alternatively use ADD https:// (which will not be cached by Docker builder)

RUN apk --no-cache add ${ADDITIONAL_PACKAGE}

# Add non root user
RUN addgroup -S app && adduser app -S -G app -u 1001 -h ${APP_ROOT} \
  && chgrp -R 0 ${APP_ROOT} && chmod -R g=u ${APP_ROOT} && chmod g=u /etc/passwd

USER 1001

ENV PATH=$PATH:${APP_ROOT}.local/bin

WORKDIR ${APP_ROOT}

COPY --chown=app:app index.py           .
COPY --chown=app:app requirements.txt   .
USER root
RUN pip install --no-cache-dir -r requirements.txt

# Build the function directory and install any user-specified components
USER 1001

RUN mkdir -p function
RUN touch ./function/__init__.py
WORKDIR ${APP_ROOT}/function/
COPY --chown=app:app function/requirements.txt	.
RUN --mount=type=secret,id=netrc,uid=1001,target=/home/app/.netrc pip install --no-cache-dir --user -r requirements.txt

# install function code
USER root
COPY --chown=app:0 function/ .

FROM build as test
ARG TEST_COMMAND=tox
ARG TEST_ENABLED=true
RUN [ "$TEST_ENABLED" = "false" ] && echo "skipping tests" || eval "$TEST_COMMAND"

FROM build as ship
WORKDIR /home/app/

# configure WSGI server and healthcheck
USER 1001

ENV fprocess="python index.py"
ENV cgi_headers="true"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:5000"

HEALTHCHECK --interval=5s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
