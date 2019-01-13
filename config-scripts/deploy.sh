#!/bin/bash
#Копируем код приложения в домашний каталог пользователя appuser:
cd /home/userapp
git clone -b monolith https://github.com/express42/reddit.git

#Переходим в директорию проекта и устанавливаем зависимости приложения:
cd reddit && bundle install

#Запускаем сервер приложения в папке проект:
puma -d

