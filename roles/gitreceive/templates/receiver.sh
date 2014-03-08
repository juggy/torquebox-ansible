#!/bin/bash
set -e

alias sudo_deploy='sudo -u deploy env PATH=$PATH'

echo "-----> Received $1@$2 for user $3"

REPO=$1
REVISION=$2
USER=$3
APP_NAME=${REPO:0: -4}

DEPLOY_DIR=/home/deploy/$1/$2
APP_DIR=/home/deploy/$1/current
TAR_DIR=/home/git/deploy/$1/$2

echo "      > Extracting revision"
sudo rm -rf $TAR_DIR
mkdir -p $TAR_DIR
cat | tar -x -C $TAR_DIR
sudo chown -R deploy.deploy $TAR_DIR

sudo -u deploy mkdir -p $DEPLOY_DIR
sudo -u deploy rm -f $APP_DIR
sudo -u deploy ln -fs $DEPLOY_DIR $APP_DIR
sudo -u deploy cp -rf $TAR_DIR/* $APP_DIR

echo "-----> Configuring Rails App"
echo "      > Writing database.yml."
sudo cp -f /home/git/database.yml $APP_DIR/config/database.yml
sudo chown deploy.deploy $APP_DIR/config/database.yml
sudo chmod +r $APP_DIR/config/database.yml

echo "      > Writing torquebox env loader."
sudo cp -f /home/git/load_torquebox_env.rb $APP_DIR/config/load_torquebox_env.rb
sudo chown deploy.deploy $APP_DIR/config/load_torquebox_env.rb
sudo chmod +r $APP_DIR/config/load_torquebox_env.rb

echo "      > Load torquebox env for rails, rake and bundle."
sudo sed -i.bak '2 i\
require_relative("../config/load_torquebox_env")\
' $APP_DIR/bin/rails
sudo sed -i.bak '2 i\
require_relative("../config/load_torquebox_env")\
' $APP_DIR/bin/bundle
sudo sed -i.bak '2 i\
require_relative("../config/load_torquebox_env")\
' $APP_DIR/bin/rake

echo "      > Running bundle install"
cd $APP_DIR
sudo -u deploy env PATH=$PATH jruby -S bundle install --without development test

echo "      > Running assets:precompile"
sudo -u deploy env PATH=$PATH DATABASE_URL=postgres://deploy:123@localhost:5432/fake RAILS_ENV=production jruby -S bundle exec rake assets:precompile

echo "-----> Deploying to torquebox"
sudo -u deploy cp -f $APP_DIR/torquebox/production-knob.yml $TORQUEBOX_HOME/jboss/standalone/deployments/$APP_NAME-knob.yml
sudo -u deploy touch $TORQUEBOX_HOME/jboss/standalone/deployments/$APP_NAME-knob.yml.dodeploy

(tail -f /var/log/torquebox/torquebox.log & P=$! ; sleep 10; kill -9 $P)

echo "=====> GIT DEPLOYMENT DONE. <====="
