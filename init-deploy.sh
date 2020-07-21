docker run --name kams -v /ssd-pny/docker/mud/kams-data/storage:/storage -v /home/sykken/gitprojects/kams-config:/conf -p 25579:25579 -d -e "INIT_PAUSE=$true" kams:latest
