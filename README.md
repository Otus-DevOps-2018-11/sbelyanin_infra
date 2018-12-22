# sbelyanin_infra

sbelyanin infra repository

HW - №3

"Способ подключения к someinternalhost в одну команду из вашего рабочего устройства"

Предварительно сделать:
Создание ключей и подключение приватного ключа к ssh агенту.
ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P ""
eval `ssh-agent`
ssh-add ~/.ssh/appuser
Копирование публичного ключа в GCP здесь не показана.


Команда для подключения:
ssh -t -A -i ~/.ssh/appuser appuser@35.210.101.213 "ssh 10.132.0.3"

-t - форсированно выдавать псевдо терминал для ssh сессии
-A - пробрасовать соединение до ssh агента
appuser - имя пользователя
35.210.101.213 - внешний ip адрес хоста bastion
10.132.0.3 - внутренний ip адрес хоста someinternalhost

Решениe для подключения из консоли при помощи команды вида ssh someinternalhost из локальной консоли рабочего устройства

Добавляем следующие строки в ~/.ssh/config
cat <<EOF>> ~/.ssh/config
Host someinternalhost
         Hostname  10.132.0.3
         user  appuser
         ProxyJump  bastion

Host bastion
         HostName  35.210.101.213
         User  appuser
         IdentityFile ~/.ssh/appuser
         ForwardAgent  yes
         RequestTTY  yes
EOF

Подключение:
[root@repo ~]# ssh someinternalhost
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.15.0-1025-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


Last login: Sat Dec 22 15:46:17 2018 from 10.132.0.2
appuser@someinternalhost:~$

### подключение к vpn  

```bash

bastion_IP = 35.228.152.71
someinternalhost_IP = 10.166.0.3

```
