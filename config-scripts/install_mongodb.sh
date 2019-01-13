#!/bin/bash

#Устанавливаем MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'

#Обновим индекс доступных пакетов и установим нужный пакет:
sudo apt update
sudo apt install -y mongodb-org

#Запускаем и добавляем в автозапуск MongoDB:
sudo systemctl start mongod
sudo systemctl enable mongod
