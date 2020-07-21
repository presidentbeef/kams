docker stop kams-dev
docker rm kams-dev
# Prod
# docker run --name kams -v /ssd-pny/docker/mud/kams-data/storage:/storage -p 25579:8888 -d kams:latest

# Dev
docker run --name kams-dev -v kams-dev-data:/storage -v /home/sykken/gitprojects/kams-dev-data/conf:/conf -p 25580:8888 -d kams:latest
