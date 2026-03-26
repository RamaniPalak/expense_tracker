#!/bin/sh

# This script injects environment variables into Serverpod config files at runtime.
# Uses placeholder substitution (safer than line-level sed replacement).

if [ -n "$DATABASE_URL" ]; then
  # Strip scheme (postgres:// or postgresql://)
  STRIPPED=$(echo "$DATABASE_URL" | sed -e 's|^postgres://||' -e 's|^postgresql://||')

  # user = everything before the first colon
  DB_USER=$(echo "$STRIPPED" | cut -d':' -f1)

  # after @ = host/dbname
  AFTER_AT=$(echo "$STRIPPED" | sed 's|.*@||')

  # host = before / (strip port if present)
  DB_HOST=$(echo "$AFTER_AT" | cut -d'/' -f1 | cut -d':' -f1)

  # dbname = after the /
  DB_NAME=$(echo "$AFTER_AT" | cut -d'/' -f2 | cut -d'?' -f1)

  # password = between first : and @
  DB_PASS=$(echo "$STRIPPED" | sed 's|[^:]*:\([^@]*\)@.*|\1|')

  echo "Injecting Database: $DB_USER@$DB_HOST/$DB_NAME"

  # Replace ONLY the named placeholders — does NOT touch port: lines
  sed -i "s|PLACEHOLDER_DB_HOST|$DB_HOST|g" config/production.yaml
  sed -i "s|PLACEHOLDER_DB_NAME|$DB_NAME|g" config/production.yaml
  sed -i "s|PLACEHOLDER_DB_USER|$DB_USER|g" config/production.yaml
  sed -i "s|PLACEHOLDER_DB_PASS|$DB_PASS|g" config/passwords.yaml
fi

if [ -n "$PUBLIC_HOST" ]; then
  echo "Injecting Public Host: $PUBLIC_HOST"
  sed -i "s|PLACEHOLDER_PUBLIC_HOST|$PUBLIC_HOST|g" config/production.yaml
fi

if [ -n "$SERVICE_SECRET" ]; then
  echo "Injecting Service Secret"
  sed -i "s|PLACEHOLDER_SERVICE_SECRET|$SERVICE_SECRET|g" config/passwords.yaml
fi

# Start the server with automatic database migration
exec ./server --apply-migrations "$@"
