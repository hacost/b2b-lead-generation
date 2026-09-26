#!/bin/sh
# Crea el rol de aplicación del Control Plane: NUNCA superusuario, NUNCA
# BYPASSRLS (CLAUDE.md, DECISIÓN-5 / Contratos de seguridad). Las migraciones
# (Alembic) corren con el rol dueño de la base ($POSTGRES_USER); el runtime de
# la aplicación se conecta exclusivamente con app_role.
#
# APP_ROLE_PASSWORD llega como variable de entorno del contenedor (definida en
# docker-compose.yml a partir de .env) — nunca hardcodeada en este script.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_role') THEN
            CREATE ROLE app_role WITH LOGIN PASSWORD '${APP_ROLE_PASSWORD}' NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE;
        END IF;
    END
    \$\$;

    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO app_role;
    GRANT USAGE ON SCHEMA public TO app_role;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
EOSQL
