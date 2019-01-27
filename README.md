# sbelyanin_infra

## ДЗ №7

 - Создан и протестирован ресурс фаирвола.
 ```bash
resource "google_compute_firewall" "firewall_ssh"
```
- Использована команда import для импортирование уже существующих ресурсов в stage файлы терраформ.

```bash
terraform import google_compute_firewall.firewall_ssh default-allow-ssh
```

- Иследована неявная зависимость ресурсов и как следствие влияние этого на очередность создание ресурсов.

<details><summary>содержимое</summary><p>

```bash
  network_interface {
    access_config = {
      nat_ip = "${google_compute_address.app_ip.address}"
```

</p></details>

 - Структуризировал ресурсы при помощи пакера - на образ с mongodb (db.json) и с установленным Ruby (app.json)
 - Разбил основной конфиг main.tf на два конфига - конфигурация с приложением (app.tf) и БД mongo (bd.tf).
 - Вынес конфигурацию фаирвола в отдельный файл vpc.tf

 - Подготовил файловую структуру для переноса ресурсов в модульную архитектуру - создал директории modules/app, module/db и modules/vpc.
 - Создал в директориях файл main.tf, variables.tf и outputs.tf и скопировал соответствующее содержимое из основного каталога.
 - Удалил db.tf и app.tf в основном каталоге и вставил в main.tf вызовы созданных модулей.

<details><summary>содержимое</summary><p>

```bash
provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source           = "../modules/app"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  node_count       = "${var.node_count}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  app_disk_image   = "${var.app_disk_image}"
  db_internal_ip   = "${module.db.db_internal_ip}"
}

module "db" {
  source           = "../modules/db"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  node_count       = "${var.node_count}"
  region           = "${var.region}"
  zone             = "${var.zone}"
  db_disk_image    = "${var.db_disk_image}"
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["${var.source_ranges_prod}"]
}

```
</p></details>
 
 - Параметризировал модуль vpc
 
 ```bash
 resource "google_compute_firewall" "firewall_ssh" {
  source_ranges = "${var.source_ranges}"
 ```
 
 - Проверил работу параметризованного модуля vpc, внося во входную переменную различные IP.

 - Создал инфраструктуру для двух окружений (stage/ и prod/), используя созданные модули.
 - Создал файл storage-bucket.tf для использования модуля storage-bucket из публичного реестра модулей.

<details><summary>содержимое</summary><p>

```bash
provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["bucket-reddit"]
}

output storage-bucket_url {
  value = "${module.storage-bucket.url}"
}
```
</p></details>

 - Проверил доступность бакета.
 
## ДЗ №7 со *  

 - Настроил хранение стайт файла в в удаленном бекенде. Вынес настройки в отдельный файл backend.tf
 
 <details><summary>содержимое</summary><p>

```bash

terraform {
  backend "gcs" {
    bucket = "bucket-reddit"
    prefix = "terraform/prod"
  }
}

```


```bash

terraform {
  backend "gcs" {
    bucket = "bucket-reddit"
    prefix = "terraform/stage"
  }
}

```

</p></details>

 - Протестировал возмонось совместного использование стайт файлов на удаленном бэкенде. Если кто-то имеющий доступ к бэкенду что-то изменяет в ресурсах, то появляется блокировка стайт файлов и невозможность внести изменения.

<details><summary>содержимое</summary><p>

```bash
 Error locking state: Error acquiring the state lock: writing "gs://bucket-reddit/terraform/stage/default.tflock" failed: googleapi: Error 412: Precondition Failed, conditionNotMet
Lock Info:
  ID:        1548587742966097
  Path:      gs://bucket-reddit/terraform/stage/default.tflock
  Operation: OperationTypeApply
  Who:       root@repo.domain
  Version:   0.11.9
  Created:   2019-01-27 11:15:18.712023857 +0000 UTC
  Info:


Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.

```
 
</p></details>


 
## ДЗ №7 с **

 - Добавил provisioner для деплоя приложения в модуль app и provisoner в модуль db для небольшой перенастройки сервиса mongodb
  
<details><summary>содержимое</summary><p>

```bash
app/main.tf:
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "../modules/app/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "file" {
    source      = "../modules/app/deploy.sh"
    destination = "/tmp/deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy.sh",
      "/tmp/deploy.sh ${join(" ", var.db_internal_ip)}",
    ]
  }


db/main.tf
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf",
      "sudo systemctl restart mongod",
    ]
  }


```

</p></details>

В случае для передачи IP адреса БД приложению в модуле app использовалась выходная переменная из модуля bd (${module.db.db_internal_ip}). Для ее передачи в VM был изменен файл производивший установку и настройку приложения

<details><summary>содержимое</summary><p>

```bash

#!/bin/bash
set -e

echo "export DATABASE_URL=$1" >> ~/.bash_profile

cd ~
git clone -b monolith https://github.com/express42/reddit.git ~/reddit
cd ~/reddit
bundle install

sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma


```


</p></details>
