#!/bin/bash

#Добавляем ключ и репозитарий MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'

#Обновим индекс доступных пакетов и установим нужные пакеты: mongoDB, Ruby и Bundler 
sudo apt update
sudo apt install -y mongodb-org ruby-full ruby-bundler build-essential

#Запускаем и добавляем в автозапуск MongoDB:
sudo systemctl start mongod
sudo systemctl enable mongod

#Копируем и запускаем код приложения от пользователя appuser
sudo su - appuser << EOF
cd ~
git clone -b monolith https://github.com/express42/reddit.gitcd ~
cd reddit && bundle install
puma -d
EOF

