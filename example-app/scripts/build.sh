#!/bin/bash

set -e

bundle install
rake test
rake cucumber