#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

#Устанавливаем ключи для репозитария MongoDB
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list

#Обновим индекс доступных пакетов и установим нужный пакет:
apt-get update
apt-get install -y mongodb-org

#Запускаем и добавляем в автозапуск MongoDB:
systemctl start mongod
systemctl enable mongod

