[![Build Status](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-11/sbelyanin_infra)

# sbelyanin_infra

# ДЗ №11

# Разработка и тестирование Ansible ролей и плейбуков

## Локальная разработка при помощи Vagrant, доработка ролей для провижининга в Vagrant:
 - Установил Vagrant, VirtualBox.
 - Создал виртуалки, описав их в Vagrantfile. Используя BOX/образ ubuntu/xenial64 из Vagrant Cloud.
 - Проверил VMs при помощи vagrant status, vagrant ssh appserver и vagrant ssh dbserver.
 - Добавил провижинеры ansible(playbooks/site.yml) в Vagrantfile.
 - Добавил плейбук base.yml в котором при помощи модуля raw на инстансы устанавливается нужная версия Python.
 - Доработал роль db - разбив провижининг на установку и настройку mongodb в разные файлы/таски. При этом перенеся весь провижининг в ansible из packer.
 - Аналогично доработал ролm app.
 - Параметризировал роль app переменными - db_host и deploy_user.
 - Переопределил переменную deploy_user через переменные ansible.extra_vars имеющие самый высокий приоритет. 
 - Протестировал конфигурацию, удалив и создав заново VM. И проверил соответственно приложение.

## Задание со *
 - Дополнил конфигурацию Vagrant для корректной работы проксирования приложения с помощью nginx:
 
<details><summary>ansible/Vagrantfile</summary><p>

```bash

    ansible.extra_vars = {
      "deploy_user" => "vagrant",
      "nginx_sites" => { "default" => 
             [
             "listen 80",
             "server_name reddit",
             "location / { proxy_pass http://127.0.0.1:9292; }"
             ]
          }
   }

```
</p></details>

## Тестирование ролей при помощи Molecule и Testinfra:
 - Создал виртуальное окружение - virtualenv -p /usr/bin/python2.7 .venv
 - Установил приложения и зависимости - pip install -r requirements.txt:
 
<details><summary>requirements.txt</summary><p>

```bash
ansible>=2.4
molecule>=2.6
testinfra>=1.10
python-vagrant>=0.5.15
```
</p></details>

 - Использовал команду molecule init для создания заготовки тестов для роли db.
 - Создал тестовую машины при помощи Molecule для тестировани (db/molecule/default/molecule.yml)
 - Создал и протестировал роль converge которая применяется к тестовой VM.
 - Напишисал тест к роли db для проверки того, что БД слушает по нужному порту:

<details><summary>test_default.py</summary><p>

```bash
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
    mongo = host.service("mongod")
    assert mongo.is_running
    assert mongo.is_enabled

# check if configuration file contains the required line
def test_config_file(host):
    config_file = host.file('/etc/mongod.conf')
    assert config_file.contains('bindIp: 0.0.0.0')
    assert config_file.is_file

# Check mongo listen on 27017 TCP port
def test_mongo_on_27017_port(host):
  mongo_tport = host.socket("tcp://0.0.0.0:27017")
  assert mongo_tport.is_listening

```
</p></details>

## Задание со *

 - Вынес роль db в отдельный репозиторийи сделал подключение роли через requirements.yml обоих окружений:
 
```bash

requirements.yml:

- src: jdauphant.nginx
  version: v2.21.1
- src: https://github.com/sbelyanin/for_otus.git
name: db

```
 - Подключил TravisCI для созданного репозитория с ролью db для автоматического прогона тестов в GCE:
 
<details><summary>.travis.yml</summary><p>

```bash
language: python
python:
- '3.6'
install:
- pip install ansible>=2.4.0 molecule apache-libcloud pycrypto
script:
- molecule create
- molecule converge
- molecule verify
after_script:
- molecule destroy
env:
  matrix:
  - GCE_CREDENTIALS_FILE="$(pwd)/credentials.json"
  global:
  - secure: mC5iHNepNywVhd47dcrnohXJLKDB96EICGhVHejxgCe3qCe3YJgJm/fY9RETMHl2PL+2MIlnoDQUw2vZ6c42hMJge7SWfpIxAlizBCegrq7tinolj96qqNAyiu8yvrQprw9TDZ7sUA5953zvtsOC08QYVRQy/rii/98ZDtBhk827x1nqd8rcag/PA4vZbLvzHmLG3rLVMGEQVvgLIMbUjfl6fi9jmluYjehdjzut/8ykmvWTn6NnhlO5o4iZ0mdI21uSU7vFMnXYzczyEjQGIGQ7aVdXxv9+mg7f8s1ViJV7WVts7Q/TjSKqvZ6CaQcfDQebangg1ntFuaIgLjFUGTp6E7ALYJCYyvwsLiSdsfoYn0TP/kTAjTfV7e3jD7/nZcgdQ23DnazGB37jt12AEzr9fmgZ8nrOpLEojtuT3ruPScdhLnpwPTdEmisBCpG/asdsmsRp3UEleKOz66tghNJYNn5DdLqc71EsHxX3YL1vY2MiZc+OKjIrWU2eqsIKnOrRsmlZ+HvhGnvkEp9PpBDN5n86A4XFDFTCoursL1Ci2kx8MkzS4AhBccsCAXXBZbPDSErt/sKnjHWqyqhf/+y3kPdqt+/2HNmVhbn0JTZ4wYjuM8Jm02j0DWgvREOQcxbhxdj1HdTLCKUfyjItZEQ8bc6RvA9vIy4gTnghzFw=
  - secure: Caxj3JXZA+9glZ1kHxSmp0+y4U5rUCrwooc9zlwzAlG032hgle/InI3+JVbFG+N4PoYstIe49kviy5MKCozQLHDclIg8qdHTW2hQeK3ZlqO1NU47hbWhuVifj7VIph+r8E6vLSyB7AsFt6VSnGy77Y6MW3njvwLCfaI5MEbj2YSevj1/RCFwqtQwdwaG9oz0MXYoF0YXa3mcjqaDv6uREeAx4T5cK6UgSDJwGlflWA00/znqfBvqkizeE4Aq047A5IGBuJOEEfsGlZCaHroAXpQPT8W/2A7TY7VgMeojT9lil8GwP5g+Vio0hB3G5gd6Zb6WajbBhH+ZGNFpBD6rjx8pg9f6VCjtBYCKqpV7XI+/xAqArITybQpVAWYlOUhmxsg+ML9wGZj3Ot8FDdtAJYVkpRxKtkDS5JU4nvoXuYS1ufU9QNHTYMFQItg/eXbcr6PqaA6iWfJSm/NzjpeZxkUXWvmKz0jJEtP3hKvDE1wKEUUdDZUdBZ8xQZWPC5XTLNgR4w829izInlwBLAkdDW18rGUddPR4KJyIoFflCe78KUPUI7h/n3tlJEvWgBxniWodgkqD226A0VFYBpmBprjNoyAmY5j6SsNuBxwmsrL8jvmTGXeZlASGmNrYjqNLrWxbP+qKaZbVbYPa06IDfaO4+WMhDp7GTdjjg5HCDtE=
  - secure: ENTk18xHld0RvNzxrpBu41M78dDyOKP1cz6r3krkaY9wQSKhN60wd2TmD+6Aro9Rt/YMj6cfwuphWA8YMcunPCcRqGUGNERJYBV8YK/zLT/XQWbX5NNj3sDR7XI+cpxKVQA1EK3emyZM7qegJYOom1o0Tb4fPdG4GBVzcemuf68uLqC5LagZfGe0n0H8Ar1IFHzPaKX5yvtRCTmbSnG/bTO6RqS0F1v0aXbzAnHHE81+UiwdBjf/CVr6CPdZYEfsjZZUIIzEByVhTbjpBhuBGadq2mmFceDApyBBzadbb3op5WOp0zD1eA8fOEsONNHTdAjualBjsj02BJ/cNNda3U0yLXTd0J/WW2/V/5hjlloqICd1MLicWshlwHaEl5CkcR0C8F9cHtiyJp3Ti6gommWBQjOE2F8zLdyKBjLtyQMmOvEJn9myslhRv5raZlnMu//3SQkpgKwBOFbcUC1Znc26x87ZBkMdjjXG4pR49Gy4hHZtyqyE86MqpbtR4GnT7MG87G0n33m77+6U1JcuPZXyW2gCCPmSb3smkcgSntj25VU25js6sC+e4yqFOkww+xj4t6eEK45Dd3L+IbgQuqCCKwdY17I1XwWmt0B/8JRXMw/eyHLAKEJIbLCKWKHc6Ad18zlI/8pQ7t90Ho6pYpd9RHTPNSQNvRzcpxrncns=
before_install:
- openssl aes-256-cbc -K $encrypted_5218d1a53638_key -iv $encrypted_5218d1a53638_iv
  -in secrets.tar.enc -out secrets.tar -d
- tar xvf secrets.tar
- mv google_compute_engine /home/travis/.ssh/
- chmod 0600 /home/travis/.ssh/google_compute_engine

notifications:
  slack:
    rooms:
secure: BdSxifFuj+aUoaHDDK2CpYYTvdn4949l0+Cv3Vj4fxRS+ddnr8/EKA2/T0CLr02D34CZNqOGwjQBLnyVtHTkQxd/ecXsWQXuH2YwAsx4p+rzYRjzb8fhKZXxa/qElYt1xpZ/4+IXJ8MGVeZ7AF/IC+gKonBDb1kBc1xqHgEWqK/fdbpMqcLq6ZRoVynBvHITld8yOWe8Cn+lKGnMF1pUB1WIpOr1xQjG4dUydMRX6cSCxF+vAg0HyPqmt5xY2hI5RZjKdIVud185FeZeYsvjHvjsHX3HtWecPRa513GBJpaeMda9XFGVVxu4Od9JjcFQVO0s5ez+ra3xvMVd6NMquGwfbQ9ynaPcj+jZScPuv1p7AUzu+vzStDWDCJh05h4HNpLKVKuaMGIbVp2pG6bYhYqhewj9PgZGkrESRWAR41jBLVBUusDejk/8fFqaL2UZ+Cu0G4gJ6UywiN04rbIag9GnJ36MzmKt/77BaQtX6+C0f+pHkCPe1zBzsoR44gUR08Lm1PlI5kATwSncnJndlHVOFYyEsmpi7oSOaMdPKsATya8E2McX0bZRnjW8hGVithQMrvcpu5MnNLVRVaGJLXUcXlCCQyjtbQR6E2y1YTAHJRXrjIcebzUWVm/SteSbu9YME/I8C8VdJ22XW/YTRVspmC2MqmgC+M9QV7xgI/U=

```
</p></details>

 - Добавлен бэйдж и уведомление в слак канал.
