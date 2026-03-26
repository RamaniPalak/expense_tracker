#!/bin/sh

# This script is used to inject environment variables into Serverpod configuration files
# at runtime. This is useful for deployment platforms like Render.

# Parse DATABASE_URL if it exists (format: postgres://user:password@host:port/dbname)
if [ -n "$DATABASE_URL" ]; then
  # Use sed to extract parts of the URL
  DB_USER=$(echo $DATABASE_URL | sed -e 's|postgres://\([^:]*\):.*|\1|')
  DB_PASS=$(echo $DATABASE_URL | sed -e 's|postgres://[^:]*:\([^@]*\)@.*|\1|')
  DB_HOST=$(echo $DATABASE_URL | sed -e 's|.*@\([^:]*\):.*|\1|')
  DB_PORT=$(echo $DATABASE_URL | sed -e 's|.*:\([0-9]*\)/.*|\1|')
  DB_NAME=$(echo $DATABASE_URL | sed -e 's|.*/\([^?]*\).*|\1|')

  echo "Injecting Database Configuration: $DB_HOST:$DB_PORT/$DB_NAME"

  # Replace database values in production.yaml
  sed -i "s|host:.*|host: $DB_HOST|g" config/production.yaml
  sed -i "s|port:.*|port: $DB_PORT|g" config/production.yaml
  sed -i "s|name:.*|name: $DB_NAME|g" config/production.yaml
  sed -i "s|user:.*|user: $DB_USER|g" config/production.yaml

  # Replace database password in passwords.yaml
  sed -i "s|database: '.*'|database: '$DB_PASS'|g" config/passwords.yaml
fi

# Replace PUBLIC_HOST if it exists
if [ -n "$PUBLIC_HOST" ]; then
  echo "Injecting Public Host: $PUBLIC_HOST"
  sed -i "s|publicHost:.*|publicHost: $PUBLIC_HOST|g" config/production.yaml
fi

# Replace SERVICE_SECRET if it exists
if [ -n "$SERVICE_SECRET" ]; then
  echo "Injecting Service Secret"
  sed -i "s|serviceSecret: '.*'|serviceSecret: '$SERVICE_SECRET'|g" config/passwords.yaml
fi

# Execute the original server command with auto-migration
exec ./server --apply-migrations "$@"
