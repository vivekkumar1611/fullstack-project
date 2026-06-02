#!/bin/bash

apt update -y

apt install docker.io git -y

systemctl start docker
systemctl enable docker

curl -L \
https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) \
-o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

cd /home/ubuntu

git clone https://github.com/vivekkumar1611/fullstack-project.git

cd fullstack-project

docker compose up -d
