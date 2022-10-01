#!/bin/bash

if [ ! -f ./web/.docker.env ]; then
    echo "Copying ./healthkart/web/.docker.env from ./healthkart/web/.docker.env.example"
    cp ./web/.docker.env.example ./web/.docker.env
    sed -i -e "s/PUT_YOUR_ID/${UID}/g" ./web/.docker.env
    cat ./web/.docker.env | grep DEV_UID
fi

docker-compose up -d --build