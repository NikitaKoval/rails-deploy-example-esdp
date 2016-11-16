#!/bin/bash

set -e

build_number=${1}

cd web-app

RAILS_ENV=production rake assets:precompile

echo ${build_number} > VERSION

tar -czf ${HOME}/artifacts/todo-list-app-${build_number}.tar.gz \
--exclude=README.md \
--exclude=LICENSE \
--exclude=features \
--exclude=cucumber* \
--exclude=test \
.
