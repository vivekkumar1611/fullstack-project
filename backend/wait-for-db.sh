#!/bin/sh
set -e

host="$1"
shift

until psql "$host" -c '\q'; do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done

echo "Postgres is up - executing command"
exec "$@"
