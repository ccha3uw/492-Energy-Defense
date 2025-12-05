#!/bin/bash
# Restore script for cyber defense database

set -e

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh /opt/cyber-defense/backups/*.sql.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Database Restore                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "⚠ WARNING: This will replace all current data!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Stopping backend service..."
cd /opt/cyber-defense
docker-compose stop backend

echo "Decompressing backup..."
TEMP_FILE="/tmp/restore_$(date +%s).sql"
gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"

echo "Restoring database..."
docker exec -i cyber-events-db psql -U postgres cyber_events < "$TEMP_FILE"

echo "Cleaning up..."
rm "$TEMP_FILE"

echo "Starting backend service..."
docker-compose start backend

echo ""
echo "✓ Restore complete!"
