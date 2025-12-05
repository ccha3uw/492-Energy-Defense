#!/bin/bash
# Backup script for cyber defense database

set -e

BACKUP_DIR="/opt/cyber-defense/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/cyber_events_$TIMESTAMP.sql"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Database Backup                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_FILE"
docker exec cyber-events-db pg_dump -U postgres cyber_events > "$BACKUP_FILE"

# Compress
echo "Compressing..."
gzip "$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Get size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo ""
echo "✓ Backup complete!"
echo "  File: $BACKUP_FILE"
echo "  Size: $SIZE"
echo ""

# Clean old backups (keep last 7 days)
echo "Cleaning old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
REMAINING=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
echo "✓ Backups in storage: $REMAINING"
echo ""

# List recent backups
echo "Recent backups:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -5 | awk '{print "  " $9 " (" $5 ")"}'
