# sbelyanin_infra

## ДЗ №6

Установлен пакет Terraform - версии 0.11.9

Для аутентификации и управления ресурсами GCP используется ADC

Создан файлы конфигурации для terraform:
- terraform/main.tf - основной файл
- terraform/outputs.tf - файл для переменных на выходе
- terraform/variables.tf - файл для определения входных переменных
- terraform/terraform.tfvars.example - пример со значениями входных переменных 

Используя file и remote-exec prvisioner добавил установку systemd unit файла для автоматического запуска Puma http сервера и установку приложения с добавлением его зависимостей в систему:
- terraform/files/puma.service - unit file
- terraform/files/deploy.sh - deploy service file

Параметризировал созданную конфигурацию переменными:
- project - ID проекта в GCP
- region - регион создания ресурсов и их запуска
- zone - зона создания ресурсов и их запуска
- public_key_path - публичный ключ для подключения к системе
- private_key_path - приватный ключ для подключения provisioner
- disk_image - семейство образов диска созданнного в прошлом занятии при помощи Packer

Исследованны параметры запуска terraform:
- init - инициализация рабочей директории в том числе подгрузка необходимых плагинсов
- plan - вывод плана действий
- apply - создание или изменение инфраструктуры
- fmt - приведение файлов конфигурации к стандартному виду
- refresh - обновление файлов состояния инфраструктуры с реальных ресурсов 
- auto-approve=true - параметр для подтверждения действий
- taint - ручное маркирование определенного рессурса для пересоздания
- validate - проверка синтаксиса файлов конфигурации

Исследован механизм провизининга - он срабатывает только при создании/удалении ресурсов. Для того чтобы перепременить их возможно использовать параметр taint. 

Используя terraform validate проверил созданную конфигурацию для создания ресурсов.

Используя terraform apply -auto-approve=true создал инстанс reddit-app и правило фаирвола.

Проверил доступ по ssh к созданному инстансу используя пару приватный-публичный ключ и доступ к сервису Puma http по порту TCP/9292.


## ДЗ №6 со *  

- Добавил в основную конфигурацию проекта описание ресурса ssh-keys :

```bash
resource "google_compute_project_metadata" "ssh-keys" {
	metadata {
    	ssh-keys = <<EOF
appuser1:${file(var.public_key_path)}
appuser2:${file(var.public_key_path)}
appuser3:${file(var.public_key_path)}
EOF
  }
}
````

для создания метаинформации ssh-keys всего проекта.

После применения конфигурации к проекту - мета информация была установленна в проект. Пользователями appuser[1..3] стало возможно подключаться по ssh использую приваткний ключ пользователя appuser.

- Добавил в веб интерфейсе ssh ключ пользователя appuser_web в метаданные проекта. Так как terraform имеет декларативное описание ресурсов, используя terraform plan можно заметить что были изменения в ресурсах которые мы описале ранее (используя локальные файлы состояния). При применении нашей конфигурации ресурс будет пересоздан.

Проблема может возникать если правки ресурсов будут производится из разных мест, разными инструментами. С одной стороны это проблема, с другой стороны это стимул использовать один инструмент для правки/деплоя и всегда иметь минимальный конфиг дрифт. Чтобы избежать этого terraform позволяет хранить файлы состояния в облакоподных сервисах и использовать их коллективно.

## ДЗ №6 с **

 - Добавил файл terraform/lb.tf:

<details><summary>содержимое</summary><p>

```bash


resource "google_compute_http_health_check" "puma-http-hc" {
  name         = "puma-http-health-check"
  request_path = "/"
  port         = "9292"

  timeout_sec        = 1
  check_interval_sec = 1
}

resource "google_compute_target_pool" "puma-target-pool" {
  name = "instance-pool"

  instances = [
    "${google_compute_instance.app.*.self_link}",
  ]

  health_checks = [
    "${google_compute_http_health_check.puma-http-hc.self_link}",
  ]
}

resource "google_compute_forwarding_rule" "puma-lb-forwarding-rule" {
  name                  = "puma-lb-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  target                = "${google_compute_target_pool.puma-target-pool.self_link}"

```

</p></details>

в нем использовал следующие рессурсы:
 - google_compute_http_health_check - для проверки работоспособности puma http на порту TCP/9292
 - google_compute_target_pool - для подключения созданных инстансов в пул
 - google_compute_forwarding_rule - для создания правила балансировки в созданный пул

Используя простое копирования ресурса в конфигирации terraform приводит к тому, что:
 - уменьшается читаемость кода
 - увеличивается возможность совершить ошибку
 - увеличивается время для правки/добавления новых рессурсов
 
 
Резюме: то, что описывается два и более раз в коде надо описывать как единое целое используя различные переменные, функции и другое.


- Удалил описание reddit-app2 из кода. Изменил файл main.tf, variables.tf, outputs.tf и lb.tf для работы с параметром count. Проверил работоспособность деплоя - все работает, балансер проверяет pumа сервера по http:9292 и передает запросы к живым сервисам.

<details><summary>изменения</summary><p>

lb.tf - приведен выше.

main.tf:

```bash

resource "google_compute_instance" "app" {
  name         = "reddit-app-${count.index}"
  count        = "${var.node_count}"

```

outputs.tf:

```bash

output "app_external_ip" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "lb_external_ip" {
  value = "${google_compute_forwarding_rule.puma-lb-forwarding-rule.ip_address}"
}


```

variables.tf:

```bash

variable "node_count" {
  default = "1"
}


```

</p></details>
