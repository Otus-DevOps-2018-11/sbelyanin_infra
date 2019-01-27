#!/bin/bash
set -e

echo "export DATABASE_URL=$1" >> ~/.bash_profile

cd ~
git clone -b monolith https://github.com/express42/reddit.git ~/reddit
cd ~/reddit
bundle install

sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
