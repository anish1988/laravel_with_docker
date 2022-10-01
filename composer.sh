#!/bin/bash
set -ex

docker-compose run --rm vendor composer "$@" \
  --ignore-platform-reqs \
  --no-plugins \
  --no-scripts \
  --no-interaction