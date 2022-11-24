#!/bin/sh
set -e

if ! whoami &> /dev/null; then
    if [ -w /etc/passwd ]; then
        echo "${USER_NAME:-app}:x:$(id -u):0:${USER_NAME:-app} user:${APP_ROOT}:/sbin/nologin" >> /etc/passwd
    fi
fi
