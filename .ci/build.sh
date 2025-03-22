#!/bin/bash

# Run "chmod +x build.sh" before running "./build.sh"

# After the build, use "SET search_path TO medsim;" to change schema (default="public")

DB_NAME="medsim"
DB_USER="postgres"
DB_PASSWORD="postgres"
SQL_FILE="../config/database.sql"

SQL_FILE_PATH=$(realpath "$(dirname "$0")/$SQL_FILE")

if ! command -v psql &> /dev/null; then
    echo "Error: PostgreSQL is not installed. Please install it first."
    exit 1
fi

if [ ! -f "$SQL_FILE_PATH" ]; then
    echo "Error: SQL file not found at $SQL_FILE_PATH"
    exit 1
elif [ ! -r "$SQL_FILE_PATH" ]; then
    echo "Error: SQL file exists but is not readable. Check permissions."
    exit 1
fi

export PGPASSWORD="$DB_PASSWORD"

USER_EXISTS=$(psql -U "$DB_USER" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")

if [ -z "$USER_EXISTS" ]; then
    echo "Error: User '$DB_USER' does not exist."
    unset PGPASSWORD
    exit 1
fi

echo "User '$DB_USER' exists."

DB_EXISTS=$(psql -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -w "$DB_NAME")

if [ -z "$DB_EXISTS" ]; then
    echo "Database '$DB_NAME' does not exist. Creating database..."
    if ! psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"; then
        echo "Error: Failed to create the database '$DB_NAME'."
        unset PGPASSWORD
        exit 1
    fi
    echo "Database '$DB_NAME' created successfully."
else
    echo "Database '$DB_NAME' already exists."
fi

SCHEMA_EXISTS=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name = 'medsim'")

if [ -z "$SCHEMA_EXISTS" ]; then
    echo "Schema 'medsim' does not exist. Creating schema..."
    if ! psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE SCHEMA medsim;"; then
        echo "Error: Failed to create schema 'medsim'."
        unset PGPASSWORD
        exit 1
    fi
    echo "Schema 'medsim' created successfully."
else
    echo "Schema 'medsim' already exists."

    TABLES_EXIST=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema = 'medsim' LIMIT 1")
    
    if [ ! -z "$TABLES_EXIST" ]; then
        echo "Tables already exist in the 'medsim' schema. Exiting..."
        unset PGPASSWORD
        exit 0
    fi
fi

echo "Creating tables..."
if ! psql -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE_PATH"; then
    echo "Error: Failed to execute SQL file."
    unset PGPASSWORD
    exit 1
fi

echo "Granting privileges to user $DB_USER..."
if ! psql -U "$DB_USER" -d "$DB_NAME" -c "GRANT USAGE ON SCHEMA medsim TO $DB_USER;" || \
   ! psql -U "$DB_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA medsim TO $DB_USER;"; then
    echo "Error: Failed to grant privileges."
    unset PGPASSWORD
    exit 1
fi

unset PGPASSWORD

echo "Database setup completed successfully!"
exit 0
