FROM python:3.10-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

WORKDIR /app

# System deps (build essentials, libpq for Postgres, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project files
COPY . .

# Expose the port Gunicorn will run on
EXPOSE 8000

# Default env values (override in real deployments)
ENV DJANGO_SETTINGS_MODULE=auravault.settings \
    PYTHONPATH=/app

# Collect static files (safe if STATIC_ROOT exists)
RUN python manage.py collectstatic --noinput || true

# Simple entrypoint to wait for DB then start Gunicorn
CMD sh -c "if [ -n \"${POSTGRES_HOST}\" ]; then \
             echo 'Waiting for database...' && \
             for i in $(seq 1 30); do \
               nc -z \"$POSTGRES_HOST\" \"${POSTGRES_PORT:-5432}\" && echo 'Database is up' && break; \
               echo 'Waiting for Postgres...'; \
               sleep 1; \
             done; \
           fi; \
           gunicorn auravault.wsgi:application --bind 0.0.0.0:8000 --workers 3"


