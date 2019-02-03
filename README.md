# sbelyanin_infra

# ДЗ №9


## Проведены работы для создания одного playbookа (reddit_app.yml) с использованием параметров для определения хостов и тэгов:

- Созданы шаблоны и обработчики событий
- Созданы задачи для деплоя кода и установку зависимостей
- Проведен деплой и проверка доступности puma app. 

<details><summary>reddit_app.yml</summary><p>

```bash
---
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0
    db_host: 10.132.0.13
  tasks:
    - name: Change mongo config file
      become: true
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      tags: db-tag
      notify: restart mongod
    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma
    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
      tags: app-tag
    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith
      tags: deploy-tag
      notify: reload puma
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle
      tags: deploy-tag
  handlers:
    - name: restart mongod
      become: true
      service: name=mongod state=restarted   
    - name: reload puma
      become: true
      systemd: name=puma state=restarted

```
</p></details>


## Проведенны работы для создания одного playbookа (reddit_app2.yml) с несколькими сценариями - разбивка на смысловые задачи:

- Проведен деплой и проверка доступности puma app. 

<details><summary>reddit_app2.yml</summary><p>

```bash

---
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure App
  hosts: app
  become: true
  tags: app-tag
  vars:
    db_host: 10.132.0.16
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma
    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes     
      
  handlers:
    - name: reload puma
      systemd: name=puma state=restarted

- name: Deploy App
  hosts: app
  become: true
  tags: deploy-tag
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith
      notify: reload puma
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle
  handlers:
    - name: reload puma
      become: true
      systemd: name=puma state=restarted

```

</p></details>


## Проведенны работы для созданию одного playbookа для каждого хоста (app.yml, db.yml и app.yml) и обьедеинение всх их в один плэйбук (site.yml). 

- Проведен деплой и проверка доступности puma app. 

<details><summary>site.yml</summary><p>
 
 ```bash
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml

```

</p></details>

 ## Переделан провижининг в packer для создания образов reddit-app redit-db.
  - созданы плэйбуки:
  
<details><summary>packer_app.yml</summary><p>
  
```bash
---
- name: Install Ruby && Bundler
  hosts: all
  become: true
  tasks:
  - name: Install ruby and rubygems and required packages
    apt: "name={{ item }} state=present"
    with_items:
      - ruby-full
      - ruby-bundler
      - build-essential

```

</p></details>
  
<details><summary>packer_db.yml</summary><p>


```bash

---
- name: Install MongoDB 3.2
  hosts: all
  become: true
  tasks:
  - name: Add APT key
    apt_key:
      id: EA312927
      keyserver: keyserver.ubuntu.com

  - name: Add APT repository
    apt_repository:
      repo: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
      state: present

  - name: Install mongodb package
    apt:
      name: mongodb-org
      state: present

  - name: Configure service supervisor
    systemd:
      name: mongod
      enabled: yes

```

</p></details>

 - созданы голден имиджи app и db в packer используя провижиниг ansible:

<details><summary>packer build</summary><p>

```bash

packer build -var-file=packer/variables.json packer/db.json
Build 'googlecompute' finished.

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-db-1549218017


packer build -var-file=packer/variables.json packer/app.json
Build 'googlecompute' finished.

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-app-1549218393

```

</p></details>

 - Удалено, заново созданно и проверенно окружение stage.  

<details><summary>recreate stage</summary><p>

```bash

terraform apply
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

./inventory.py --refresh-cache

ansible-playbook site.yml --check
reddit-app-0               : ok=9    changed=7    unreachable=0    failed=0
reddit-db-0                : ok=3    changed=2    unreachable=0    failed=0


ansible-playbook site.yml
reddit-app-0               : ok=9    changed=7    unreachable=0    failed=0
reddit-db-0                : ok=3    changed=2    unreachable=0    failed=0

```

</p></details>


# Задание со *

 - Выбран вариант с gce.py - проверенный и хорошо описанный dynamic inventory. Из минусов - создание JSON credentials.
 - Сам скрипт скопирован в ansible/inventory.py. 
 - В inventory.py была изменена переменная для дефолтного расположения файла gce.ini на gcp/gce.ini.
 - Создана директория ansible/gcp. В нее скопированы отредактированные файлы infra.json и gce.ini. (в репозитарии находятся примеры *.example)
 - Протестирован скрипт

<details><summary>inventory.py</summary><p>

```bash
ansible]$ ansible all -m ping
reddit-db-0 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
reddit-app-0 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
 
```
</p></details>

 - В ansible.cfg скрипт установлен в качестве дефолтного ивентори. Добавлена переменная из описания хоста в плейбук app.yml для установки связанности от приложения к бд по локальной сети. 

<details><summary>dynamic inventory</summary><p>

```bash

ansible.cfg:
[defaults]
inventory = ./inventory.py
 
 
app.yml:
- name: Configure App
  hosts: reddit-app-0
  become: true
  vars:
    - db_host: "{{ hostvars['reddit-db-0']['gce_private_ip'] }}"
 ```
 </p></details>


 - Проверенно окружение stage.
