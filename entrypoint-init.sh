#!/bin/bash

if [ -d "/storage" ]
then
  echo "Storage found at /storage, loading game world from that..."

  if [ -d /app/storage]
  then
    mv /app/storage /app/storage-old
  fi
  ln -s /storage /app/storage
else
  echo "Nothing mounted at /storage, using storage included in image..."
  echo "NOTE: THIS WILL NOT PERSIST BETWEEN RESTARTS!"
fi


echo "Running server..."
ruby /app/server.rb
