[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_infra)

# sbelyanin_infra

# ДЗ №10


## Работа с ролями и окружениями Ansible:
 - Создал Ansible роли: app (приложение) и db.
 - Переменные, таски, шаблоны и хендлеры вынесенны в ролевую структуру директорий (для stage и prod окружения).
 - Файлы инвентори и зависимостей также вынесены в ansible/environments.
 - Проверил тестовую прокатку и затем делполой на инфраструктуру с использованием созданных ролей.
 - Настроена и добавлена роль jdauphant.nginx (в app.yml) из портала Ansible Galaxy при помощи утилиты ansible-galaxy.
 - Добавлен тег http-server в образ инстанса app при помощи packer для работы nginx прокси по стандартному порту (80/TCP).
 - перенес все плэйбуки в ansible/playbooks и все что не относится к текущим задачам в ansible/old.
 - Пересоздал образы и инстансы для инфраструктуры.
 - Подготовил работу Ansible для работы с dynamic registry и использованием ролей.
 - Протестировал и сделал накатку ролей ansible через обьединяющий плэйбук site.yml на инфраструктуру. Проверил работоспособность.
 
## Работа с Ansible Vault:
 - Создал файл ~/.ansible/vault.key - мастер-пароль (aka vault key).
 - Добавил ссылку на него в ansible.cfg
 - Создал playbook users.yml и подключил данную роль в site.yml 
 - файлы с описанием пользователей (ansible/environments/$ENV/credentials.yml) и зашифровал их используя ansible-vault encrypt и файла vault key.
 - Проверил что файлы с пользователями зашифрованы.
 - Накатил обновления на ифраструктуру.
 - Проверил что пользователи создались в системе при помощи cat /etc/passwd.
 - Протестировал возможность работы от данных пользователей при помощи команды su.

## Задание со ⭐: Работа с динамическим инвентори:
 - Настроил использование динамического инвентори для окружений stage и prod. Использовал скрипт gce.py и его обвязку из прошлого ДЗ.
 - Вынес настройку скрипта в домашний каталог пользователя - ~/gcp/gce.ini и ~/gcp/infra.json.
 - Добавил групповые переменные в stage и prod окружение - tag_reddit-app.yml и tag_reddit-db.yml
 - В ansible.cfg скрипт установлен в качестве дефолтного ивентори. 
 - Добавлена переменная из описания хоста (reddit-db-0) в в групповые переменные (tag_reddit-app.yml) для установки связанности от приложения к бд по локальной сети.
 
<details><summary>inventory</summary><p>

```bash

ansible.cfg:
[defaults]
inventory = ./inventory.py

tag_reddit-app.yml:
db_host: "{{ hostvars['reddit-db-0']['gce_private_ip'] }}"

```
</p></details>

- Протестировал работоспособность инфраструктуры с использованием динамического инвентори.

## Задание с ⭐⭐: Настройка TravisCI
 - Использовал возможность использования комбинации переменных окружения travis ci.
 - Т.к. все нужные проверки (указанные в задании) уже есть в репозитарии для проверки - решил использовать их:
 packer validate - packer-base
 terraform validate и tflint - terraform-2
 ansible-lint - ansible-3
 - Добавлен дополнительный сет переменной BR в .travis.yml
 
 <details><summary>BR set</summary><p>

```bash

 env:
  - BR=terraform-2
  - BR=packer-base
  - BR=ansible-3
  - BR=mainbranch

```
</p></details>

 - Билд разбивается на 4 задачи:
 ```bash
  - packer validate - packer-base
  - terraform validate и tflint - terraform-2
  - ansible-lint - ansible-3
  - mainbranch - main branch (для билда текущей ветки)
```
 - Далее перед запуском основновного скрипта происходит подмена переменной TRAVIS_PULL_REQUEST_BRANCH значением из переменной BR:
 ```bash
 before_install:
  - if [ ! $BR == 'mainbranch' ]; then if [ ! $TRAVIS_PULL_REQUEST_BRANCH == "" ] || [ $TRAVIS_BRANCH == 'master' ]; then TRAVIS_PULL_REQUEST_BRANCH="$BR";  else TRAVIS_PULL_REQUEST_BRANCH="none";  fi fi
  - curl https://raw.githubusercontent.com/express42/otus-homeworks/2018-11/run.sh | bash
 ```
 - Подмена происходит только при выполнении задания с переменной BR установленной не в основное задание (! $BR == 'mainbranch') и при пуше в master ветку, либо при PR.
 - Плюс данного подхода - все тесты хранятся в репозитарии. Минус - при любом пуше/PR создаются 4 задания, но с учетом того что в несколько потоков задания должны отрабатываться быстрее и ненужные дополнительные задания обрабатываются очень быстро этот минус считаю несущественным.
 - В README.md добавлен бейдж со статусом билда.

