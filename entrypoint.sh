#!/bin/bash

if [ -d "/storage" ]
then
  echo "Storage found at /storage, loading game world from that..."
#  if [ -d /app/storage ]
#  then
#    mv /app/storage /app/storage-old
#  fi
#  ln -s /storage /app/storage
else
  echo "Nothing mounted at /storage, using storage included in image..."
  echo "NOTE: THIS WILL NOT PERSIST BETWEEN RESTARTS!"
fi

cd /app

if [ -v INIT_PAUSE ]
then
  echo "INIT_PAUSE specified, sleeping..."
  while [ 1 -eq 1 ]
  do
    sleep 5
  done
fi

#if [ -d "/conf" ]
#then
  #mv /conf /app/conf -f
#fi

echo "Running server..."
ruby ./server.rb >> /proc/1/fd/1
# The /proc/1/df/1 just indicates to send output to stdout
