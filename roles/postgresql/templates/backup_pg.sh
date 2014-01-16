#!/bin/sh
sudo -u postgres /usr/bin/pg_dumpall -c --no-acl --no-owner > /tmp/backup/all_db_$(date +%Y-%m-%d).dump

echo "[default]
access_key = {{ postgresql_backup.aws.access_key }}
secret_key = {{ postgresql_backup.aws.secret_key }}
bucket_location = {{ postgresql_backup.aws.location }}" > ~/s3cmd.config

s3cmd sync /tmp/backup/ s3://porkepic-db-backup/ -c ~/s3cmd.config

rm ~/s3cmd.config