#!/bin/bash -e

#Копируем код и устанавливаем зависимости приложения от пользователя appuser
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

#Создаем сервис puma, добавляем в автозапуск и стартуем его
sudo -i << EOF
mv -f /home/appuser/puma.service /lib/systemd/system/puma.service
systemctl daemon-reload
systemctl enable puma.service
systemctl start puma.service
EOF

