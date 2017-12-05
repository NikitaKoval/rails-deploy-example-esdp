#!/bin/bash

set -e

cd web-app

bundle install
rake db:migrate RAILS_ENV=test
rake test
bundle exec cucumber