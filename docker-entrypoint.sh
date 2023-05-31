#!/bin/sh
set -e

if [ $1 = 'bin/rails' ] && [ $2 = 's' ] ; then
    rm -f ./tmp/pids/server.pid
    bin/rails db:prepare
fi

exec "$@"
