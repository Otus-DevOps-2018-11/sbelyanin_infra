# sbelyanin_infra

## ДЗ №9





 - Проверены системные компоненты для установки и работы работы с ansible:

<details><summary>содержимое</summary><p>

```bash
python --version
Python 2.7.5

pip --version
pip 19.0.1

ansible --version
ansible 2.7.6

```
</p></details>

 - Поднята инфраструктура окружения stage при помощи terraform:

<details><summary>содержимое</summary><p>

```bash
terraform apply
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
app_external_ip = 34.76.119.239
db_external_ip = 35.205.17.199

```
</p></details>

 - Создал инвентори файл ansible/inventory:

<details><summary>содержимое</summary><p>

```bash
appserver ansible_host=34.76.119.239 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser
dbserver ansible_host=35.205.17.199 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser

```
</p></details>

 - Убедился, что Ansible может управлять хостами appserver и dbserver используя модуль ping:

<details><summary>содержимое</summary><p>
 
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
</p></details>


 - Добавил различные параметры ansible в кофигурационный файл ansible.cfg:

<details><summary>содержимое</summary><p>

```bash

ansible/ansible.cfg:
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False

```
</p></details>

 - Изменил файл инвентори с учетом того, что некоторые параметры стали избыточны:

<details><summary>содержимое</summary><p>

```bash

ansible/inventory:
appserver ansible_host=34.76.119.239
dbserver ansible_host=35.205.17.199

```
</p></details>

 - Проверил работу используя модуль command, позволяющий запускать произвольные команды:

<details><summary>содержимое</summary><p>

```bash

ansible appserver -m command -a uptime
appserver | CHANGED | rc=0 >>
 19:21:07 up  1:50,  1 user,  load average: 0.00, 0.00, 0.00

ansible dbserver -m command -a uptime
dbserver | CHANGED | rc=0 >>
 19:21:18 up  1:51,  1 user,  load average: 0.00, 0.00, 0.00

```
</p></details>

 - Определил группы хостов в инвентори файле ansible/inventory и проверим работу с ними:

<details><summary>содержимое</summary><p>

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
</p></details>


 - Создал файл inventory.yml, используя YAML перенес в него текущие записи inventory и проверил работу:

<details><summary>содержимое</summary><p>

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
</p></details>


 - Проверил что на app и bd сервере стоят компоненты для работы приложения и статус сервиса mongodb соответственно:

<details><summary>содержимое</summary><p>

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
</p></details>


 - Склонировал репозиторий с приложением на app сервер (репозитарий уже присутствует - ДЗ со звездочками):

<details><summary>содержимое</summary><p>

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
</p></details>

 - Создал плейбук ansible/clone.yml и выполнил его. Удалил его и выполнил заново плейбук:

<details><summary>содержимое</summary><p>

```bash
ansible-playbook clone.yml
PLAY RECAP ************************************************************************************
appserver                  : ok=2    changed=0    unreachable=0    failed=0

PLAY RECAP ************************************************************************************
appserver                  : ok=2    changed=1    unreachable=0    failed=0

```
</p></details>

Т.к. при первом прогоне плей бука репозитарий уже существовал и накатка не изменила его, то ansible показал что изменений нету. При втором прогоне, после удаления, произошли изменения в файловой системе - ansible показал это "changed=1".

## ДЗ №8 со *  

 - Создал скрипт-парсер конфиг файла inventory в формате ini. В скрипте захордкоженно имя входного файла. При запуске с параметрами:
 --list выдает на выходе JSON для Ansible >= v1.3 возвращая элемент верхнего уровня с именем _meta, в котором могут быть перечислены все переменные для хостов.
 --host выдает заглушку "{"_meta": {"hostvars": {}}}"
 любые другие параметры также получают заглушку "{}"
  
<details><summary>inventory.sh</summary><p>

```bash
#!/bin/bash

function print_list()
{

LG=""
LM=""
TR=0
IT=0
IM=1

FILE=inventory

LG+="{\n"
LM+="\t\"_meta\": {\n\t   \"hostvars\": {\n\t\t"

while read LINE; do
  if [[ $LINE == *\[*\]* ]]
  then

# echo ""> test.sem


     if [[ $TR == 1 ]]
     then
       LG+="],\n\t   \"vars\": {}\n\t},\n"
     fi

     LG+="\t"`echo $LINE | sed 's/\[*\([a-zA-Z_]*\).*/"\1": {/'`"\n\t   \"hosts\": ["
     TR=1
     IT=1

#TR = 1 вошли в блок
#IT = 1 первый итем в блоке
#IM = 1 первый итем в мета блоке
#LG - строка вывода основных блоков/групп
#LM - строка вывода для мета информации

  elif [[ $LINE == *" "*"="* ]]
  then

      if [[ $IT == 0 ]]
      then
        LG+=", "
      fi

      if [[ $IM == 0 ]]
      then
        LM+=",\n\t\t"
      fi


      LG+=`echo $LINE | sed 's/\(.*\)* ansible_host=.*/\"\1\"/'`
      
      LM+=`echo $LINE | sed 's/\(.*\)* ansible_host=.*/\"\1\"/'`
      LM+=": { \"ansible_host\" : \""`echo $LINE | sed 's/.*ansible_host=\(.*\)/\1/'`"\" }"

      IM=0
      IT=0
  fi
    
done < $FILE



if [[ $TR == 1 ]]
then
   LG+="],\n\t   \"vars\": {}\n\t},\n"
fi

if [[ $IM == 0 ]]
then
   LM+="\n\t   }\n\t}\n"
fi

LG+="$LM"

LG+="}\n"

echo -e $LG
echo -e $LG > test.json

#echo -e $LM
}

case "$1" in
        --list) print_list ;;
        --host) echo '{"_meta": {"hostvars": {}}}' ;;
         *)  echo "{ }" ;;
esac

```

</p></details>

 - Создал при помощи скрипта файл ответ в формате JSON для динамического инвентори:

  
<details><summary>inventory.json</summary><p>

```bash

 {
	"app": {
	 "hosts": ["appserver"],
	 "vars": {}
	},
	"db": {
	 "hosts": ["dbserver"],
	 "vars": {}
	},
	"_meta": {
	 "hostvars": {
		"appserver": { "ansible_host" : "34.76.119.239" },
		"dbserver": { "ansible_host" : "34.76.168.129" }
	 }
	}
}
 
```

</p></details>

 - Дополнительно поправил ansible.cfg строку inventory:

<details><summary>ansible.cfg</summary><p>
 
```bash

[defaults]
inventory = ./inventory.sh
```
</p></details>

- Проверка работоспособности:
 
<details><summary>Итоги</summary><p>

```bash

ansible  all -m ping
appserver | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
dbserver | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

```
</p></details>

 - Отличия динамического инвентори от статического - возможнось работать с большим количеством динамических инстансов. В синтаксисе различия на уровне элемента верхнего уровня "_met".
