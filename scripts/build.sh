#!/bin/bash

set -e

cd web-app

bundle install
rake test
rake cucumber