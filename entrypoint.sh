#!/bin/sh
set -e

if [ -n "$POSTGRES_HOST" ]; then
  echo "Waiting for database $POSTGRES_HOST:$POSTGRES_PORT..."
  i=1
  while [ $i -le 30 ]; do
    nc -z "$POSTGRES_HOST" "${POSTGRES_PORT:-5432}" && break
    echo "Waiting for Postgres... ($i/30)"
    i=$((i + 1))
    sleep 1
  done
fi

echo "Running migrations..."
python manage.py migrate --noinput

echo "Starting Gunicorn..."
exec gunicorn auravault.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 3
