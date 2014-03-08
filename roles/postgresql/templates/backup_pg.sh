#!/bin/bash
backup_dir="/tmp/backup"
databases=`sudo -u postgres psql -q -x -t -c "\l" | grep 'Name' | sed 's/ //g' | sed 's/Name|//g'`

echo "Starting backup of databases "
for i in $databases; do
  dateinfo=`date '+%Y-%m-%d %H:%M:%S'`
  timeslot=`date '+%Y%m%d%H%M'`
  sudo -u postgres /usr/bin/vacuumdb -z $i >/dev/null 2>&1
  sudo -u postgres /usr/bin/pg_dump -Fc --no-acl --no-owner $i > $backup_dir/$i-database-$timeslot.dump
  echo "Backup and Vacuum complete on $dateinfo for database: $i "
done

echo "[default]
access_key = {{ postgresql_backup.aws.access_key }}
secret_key = {{ postgresql_backup.aws.secret_key }}
bucket_location = {{ postgresql_backup.aws.location }}" > ~/s3cmd.config

s3cmd sync --no-delete-removed /tmp/backup/ s3://porkepic-db-backup/ -c ~/s3cmd.config

rm ~/s3cmd.config

rm $backup_dir/*

echo "Done backup of databases"