# sbelyanin_infra

## ДЗ №8

 - Проверены системные компоненты для установки и работы работы с ansible:

```bash
python --version
Python 2.7.5

pip --version
pip 19.0.1

ansible --version
ansible 2.7.6

```

 - Поднята инфраструктура окружения stage при помощи terraform:

```bash
terraform apply
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
app_external_ip = 34.76.119.239
db_external_ip = 35.205.17.199

```


 - Создал инвентори файл ansible/inventory:

```bash
appserver ansible_host=34.76.119.239 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
dbserver ansible_host=35.205.17.199 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
```

 - Убедился, что Ansible может управлять хостами appserver и dbserver используя модуль ping:

```bash

ansible appserver -i ./inventory -m ping
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

ansible dbserver -i ./inventory -m ping
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

```

 - Добавил различные параметры ansible в кофигурационный файл ansible.cfg:
  
```bash

ansible/ansible.cfg:
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False

```

 - Изменил файл инвентори с учетом того, что некоторые параметры стали избыточны:

```bash

ansible/inventory:
appserver ansible_host=34.76.119.239
dbserver ansible_host=35.205.17.199

```

 - Проверил работу используя модуль command, позволяющий запускать произвольные команды:

```bash

ansible appserver -m command -a uptime
appserver | CHANGED | rc=0 >>
 19:21:07 up  1:50,  1 user,  load average: 0.00, 0.00, 0.00

ansible dbserver -m command -a uptime
dbserver | CHANGED | rc=0 >>
 19:21:18 up  1:51,  1 user,  load average: 0.00, 0.00, 0.00


```

 - Определил группы хостов в инвентори файле ansible/inventory и проверим работу с ними:

```bash
ansible/inventory:
[app]
appserver ansible_host=34.76.119.239

[db]
dbserver ansible_host=35.205.17.199

ansible app -m ping
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ansible db -m ping
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

``` 

 - Создал файл inventory.yml, используя YAML перенес в него текущие записи inventory и проверил работу:

```bash
ansible/inventory.yml:
all:
  children:
    app:
      hosts:
        appserver:
           ansible_host: 34.76.119.239
    db:
      hosts:
        dbserver:
           ansible_host: 35.205.17.199

ansible all -m ping -i inventory.yml
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

```

 - Проверил что на app и bd сервере стоят компоненты для работы приложения и статус сервиса mongodb соответственно:

```bash

ansible app -m shell -a 'ruby -v; bundler -v'
appserver | CHANGED | rc=0 >>
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
Bundler version 2.0.1

ansible db -m systemd -a name=mongod
dbserver | SUCCESS => {
    "changed": false,
    "name": "mongod",
    "status": {
        "ActiveState": "active",

ansible db -m service -a name=mongod
dbserver | SUCCESS => {
    "changed": false,
    "name": "mongod",
    "status": {
        "ActiveState": "active",

``` 

 - Склонировал репозиторий с приложением на app сервер (репозитарий уже присутствует - ДЗ со звездочками):

```bash
ansible app -m git -a \
> 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
appserver | SUCCESS => {
    "after": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "before": "5c217c565c1122c5343dc0514c116ae816c17ca2",
    "changed": false,
    "remote_url_changed": false
}

``` 

 - Создал плейбук ansible/clone.yml и выполнил его. Удалил его и выполнил заново плейбук:

```bash
ansible-playbook clone.yml
PLAY RECAP ************************************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0

PLAY RECAP ************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0

```
Т.к. при первом прогоне плей бука репозитарий уже существовал и накатка не изменила его, то ansible показал что изменений нету. При втором прогоне, после удаления, произошли изменения в файловой системе - ansible показал это "changed=1".


<details><summary>содержимое</summary><p>

</p></details>

## ДЗ №8 со *  

