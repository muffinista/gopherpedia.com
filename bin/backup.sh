#!/bin/bash

mysqldump -u $MYSQL_BACKUP_USER \
          --password=$MYSQL_BACKUP_PASSWORD \
          -P $MYSQL_BACKUP_PORT \
          -h $MYSQL_BACKUP_HOST \
          $MYSQL_BACKUP_DATABASE | restic -r s3:s3.amazonaws.com/muffinlabs/backup backup --tag gopherpedia --stdin --stdin-filename $MYSQL_BACKUP_DATABASE.sql
