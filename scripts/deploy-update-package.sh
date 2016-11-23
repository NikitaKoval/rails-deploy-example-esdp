#!/bin/bash

set -e

host=${1}
id_rsa_key_path=${2}
instance_name=${3}
build_number=${4}
package_name=todo-app-${build_number}.tar.gz
package_name_path=${HOME}/artifacts/${package_name}

chmod 700 keys
chmod 600 ${id_rsa_key_path}

scp -i ${id_rsa_key_path} -p scripts/apply-update.sh ${host}:~
scp -i ${id_rsa_key_path} ${package_name_path} ${host}:~

ssh -i ${id_rsa_key_path} ${host} <<EOL
chmod +x apply-update.sh
sudo ./apply-update.sh ${instance_name} ${package_name}
EOL

./create-deployment-package.sh ${BUILD_NUMBER}