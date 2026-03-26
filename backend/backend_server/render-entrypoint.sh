#!/bin/sh

# This script injects environment variables into Serverpod config files at runtime.

# Parse DATABASE_URL (format: postgresql://user:password@host:port/dbname OR postgres://...)
if [ -n "$DATABASE_URL" ]; then
  # Strip the scheme (postgres:// or postgresql://)
  STRIPPED=$(echo "$DATABASE_URL" | sed -e 's|^postgres://||' -e 's|^postgresql://||')

  # Extract user (everything before the first colon)
  DB_USER=$(echo "$STRIPPED" | sed -e 's|:.*||')

  # Extract password (between first colon and @)
  DB_PASS=$(echo "$STRIPPED" | sed -e 's|[^:]*:\([^@]*\)@.*|\1|')

  # Extract host (between @ and the next / or end)
  DB_HOST=$(echo "$STRIPPED" | sed -e 's|.*@\([^/:]*\).*|\1|')

  # Extract port (between last : before / and /)
  DB_PORT=$(echo "$STRIPPED" | sed -e 's|.*@[^:]*:\([0-9]*\)/.*|\1|')
  # Default to 5432 if port is empty or same as DB_HOST (no port in URL)
  if [ -z "$DB_PORT" ] || [ "$DB_PORT" = "$DB_HOST" ]; then
    DB_PORT="5432"
  fi

  # Extract dbname (everything after the last /)
  DB_NAME=$(echo "$STRIPPED" | sed -e 's|.*/||' -e 's|?.*||')

  echo "Injecting Database Configuration: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

  # Inject into production.yaml using line-aware replacement
  sed -i "s|^  host:.*|  host: $DB_HOST|" config/production.yaml
  sed -i "s|^  port:.*|  port: $DB_PORT|" config/production.yaml
  sed -i "s|^  name:.*|  name: $DB_NAME|" config/production.yaml
  sed -i "s|^  user:.*|  user: $DB_USER|" config/production.yaml

  # Inject password into passwords.yaml
  sed -i "s|database: '.*'|database: '$DB_PASS'|" config/passwords.yaml
fi

# Inject PUBLIC_HOST
if [ -n "$PUBLIC_HOST" ]; then
  echo "Injecting Public Host: $PUBLIC_HOST"
  sed -i "s|publicHost: PLACEHOLDER_PUBLIC_HOST|publicHost: $PUBLIC_HOST|" config/production.yaml
  sed -i "s|publicHost: insights.PLACEHOLDER_PUBLIC_HOST|publicHost: insights.$PUBLIC_HOST|" config/production.yaml
  sed -i "s|publicHost: app.PLACEHOLDER_PUBLIC_HOST|publicHost: app.$PUBLIC_HOST|" config/production.yaml
fi

# Inject SERVICE_SECRET
if [ -n "$SERVICE_SECRET" ]; then
  echo "Injecting Service Secret"
  sed -i "s|serviceSecret: '.*'|serviceSecret: '$SERVICE_SECRET'|" config/passwords.yaml
fi

# Execute the server with auto-migration
exec ./server --apply-migrations "$@"
