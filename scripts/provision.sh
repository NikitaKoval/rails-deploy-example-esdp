#!/bin/bash

set -e

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

BASH_GREEN_COLOR="\033[0;31m"
BASH_RESET_COLOR="\033[0m"

RBENV_PATH=${HOME}/.rbenv
RBENV_BIN_PATH=${RBENV_PATH}/bin
RBENV_SHIMS_PATH=${RBENV_PATH}/shims
RUBY_VERSION=2.3.1
MYSQL_DB_NAME="todo_db"
MYSQL_USER_NAME="todouser"

package_name=${1}
hostname=${2}
instance_name=${3}

project_root=${HOME}/todo-list-app

echo "# Installing system dependencies"
apt-get update
apt-get install pwgen
mysql_root_password=$(pwgen -1 12)
mysql_user_password=$(pwgen -1 12)
rails_secret=$(pwgen -1 128)

cat >> /etc/sudoers <<EOL
${SUDO_USER} ALL=(ALL:ALL) NOPASSWD:${HOME}/install-update.sh
EOL

echo "mysql-server mysql-server/root_password password ${mysql_root_password}" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password ${mysql_root_password}" | debconf-set-selections

apt-get install -y nginx build-essential mysql-server libmysqlclient-dev unzip libssl-dev libreadline-dev libsqlite3-dev

echo "# Configuring MySQL"
mysql -uroot -p${mysql_root_password} -e "create database ${MYSQL_DB_NAME} character set utf8 collate utf8_general_ci;"
mysql -uroot -p${mysql_root_password} -e "create user '${MYSQL_USER_NAME}'@'localhost' identified by '${mysql_user_password}';grant all privileges on ${MYSQL_DB_NAME}.* to '${MYSQL_USER_NAME}'@'localhost';flush privileges;"

su ${SUDO_USER} <<USERCOMMANDS
cat > ${HOME}/secrets.txt <<EOL
mysql root password: ${mysql_root_password}
mysql user: ${MYSQL_USER_NAME}
mysql user password: ${mysql_user_password}
rails secret key base: ${rails_secret}
EOL

cat > ${HOME}/.my.cnf <<EOL
[client]
user=${MYSQL_USER_NAME}
password=${mysql_user_password}
EOL

echo "# Installing rbenv & ruby-build"
git clone https://github.com/rbenv/rbenv.git ${RBENV_PATH}
cd ${RBENV_PATH} && src/configure && make -C src
mkdir -p ${RBENV_PATH}/plugins
git clone https://github.com/rbenv/ruby-build.git ${RBENV_PATH}/plugins/ruby-build

cd ${HOME}

PATH=${RBENV_BIN_PATH}:${RBENV_SHIMS_PATH}:$PATH

echo "# Installing ruby"
rbenv install ${RUBY_VERSION}
rbenv local ${RUBY_VERSION}
rbenv global ${RUBY_VERSION}

echo "# Installing bundler"
gem install bundler

echo "# Configuring app"
mkdir -p ${project_root}
tar -xzf ${package_name} -C ${project_root}
cd ${project_root}
rbenv local ${RUBY_VERSION}
bundle install

cat > ${project_root}/config/environments/${instance_name}.rb <<EOL
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = false
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
end
EOL

cat >> ${project_root}/config/database.yml <<EOL

${instance_name}:
  adapter: mysql2
  encoding: utf8
  database: todo_db
  username: todouser
  password: ${mysql_user_password}
  host: 127.0.0.1
  port: 3306
EOL

cat >> ${project_root}/config/secrets.yml <<EOL
${instance_name}:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
EOL
USERCOMMANDS

cat > /etc/systemd/system/puma-${instance_name}.service <<EOL
[Unit]
Description=puma daemon
After=network.target

[Service]
Environment=RAILS_ENV=demo
Environment=SECRET_KEY_BASE=${rails_secret}
User=deploy
Group=deploy
WorkingDirectory=/home/deploy/todo-list-app
ExecStart=${RBENV_BIN_PATH}/rbenv exec bundle exec puma -C config/puma.rb
ExecStop=${RBENV_BIN_PATH}/rbenv exec bundle exec pumactl -S tmp/pids/puma.state stop
[Install]
WantedBy=multi-user.target
EOL

echo "# Starting puma service"
systemctl enable puma-${instance_name}.service
systemctl start puma-${instance_name}.service

echo "# Configuring nginx"
cat > /etc/nginx/sites-available/${hostname} <<EOL
upstream puma {
  server unix:${project_root}/tmp/sockets/puma.sock fail_timeout=0;
}

server {
    listen 80;
    server_name ${hostname};

    root ${project_root};

    location ^~ /assets/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
    }

    location /version {
        alias ${project_root}/VERSION;
        add_header Content-Type text/plain;
    }

    try_files \$uri/index.html \$uri @puma;
    location / {
        proxy_pass http://puma;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
    }
}
EOL

ln -s /etc/nginx/sites-available/${hostname} /etc/nginx/sites-enabled
systemctl restart nginx.service

echo "# Creating archive with configs"
cd ${project_root}
tar -czf ${HOME}/todo-${instance_name}-configs.tar.gz config/environments/${instance_name}.rb config/database.yml config/secrets.yml

echo -e "${BASH_GREEN_COLOR}#######################################\n\n"
echo "Please copy archive, extract in project root and commit changes to repo\n\n"
echo "${HOME}/todo-${instance_name}-configs.tar.gz\n\n"
echo "Your MySQL passwords and rails secret stored in this file:\n"
echo "${HOME}/secret.txt\n\n"
echo -e "#######################################${BASH_RESET_COLOR}"
