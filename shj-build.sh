#!/bin/bash

set -e

if [ "$#" -ne 1 ]; then
   echo "Usage: $0 <config file>"
   exit 1
fi
if [ ! -f $1 ]; then
   echo "$1 not found."
   exit 1
fi

. $1
cat $1

# Docker Volume の作成
if ! docker volume inspect $MARIA_VOLUME > /dev/null 2>&1; then
   echo "Create $MARIA_VOLUME docker volume"
   docker volume create $MARIA_VOLUME
fi

if ! docker volume inspect $SHJ_VOLUME > /dev/null 2>&1; then
   echo "Create $SHJ_VOLUME docker volume"
   docker volume create $SHJ_VOLUME
fi

# Docker イメージのビルド
DOCKER_IMAGE_NAME=shj-$SHJ_NAME
echo "Building Docker image: $DOCKER_IMAGE_NAME"

docker build \
    --build-arg SHJ_NAME=$SHJ_NAME \
    --build-arg SHJ_URI=$SHJ_URI \
    --build-arg SMTP_HOST=$SMTP_HOST \
    --build-arg MARIA_DATADIR=$MARIA_DATADIR \
    --build-arg MARIA_VOLUME=$MARIA_VOLUME \
    --build-arg SHJ_DATADIR=$SHJ_DATADIR \
    --build-arg SHJ_VOLUME=$SHJ_VOLUME \
    -t $DOCKER_IMAGE_NAME . | tee build.log

echo "✅ Docker image $DOCKER_IMAGE_NAME built successfully."

# コンテナの起動
echo "Run Docker container sharif-judge-$SHJ_NAME from $DOCKER_IMAGE_NAME image"
docker run -d --name sharif-judge-$SHJ_NAME \
   -p $PORT:80 \
   -v $MARIA_VOLUME:/var/lib/mysql \
   -v $SHJ_VOLUME:/var/shjdata \
   $DOCKER_IMAGE_NAME
echo "✅ Container sharif-judge-$SHJ_NAME is running."
