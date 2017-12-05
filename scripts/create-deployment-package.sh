#!/bin/bash

set -e

version=${1}

cd web-app

RAILS_ENV=production rake assets:precompile

echo ${version} > VERSION

tar -czf ${HOME}/artifacts/todo-list-app-${version}.tar.gz \
--exclude=README.md \
--exclude=LICENSE \
--exclude=features \
--exclude=cucumber* \
--exclude=test \
.
