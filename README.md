# sbelyanin_infra

## ДЗ №5

Установлен Packer

Для аутентификации и управления ресурсами GCP установлен Application Default Credentials (ADC)

Создан Packer template
- ubuntu16.json

Используя shell provisioner добавил установку ruby и mongodb
- scripts/install_ruby.sh
- scripts/install_mongodb.sh

Параметризировал созданный шаблон
- ID проекта (обязательно)
- source_image_family (обязательно)
- machine_type

Исследованны другие опции builder для GCP
- Описание образа
- Размер и тип диска
- Название сети
- Теги

Используя packer validate проверил шаблон для создания голден имиджа.


Используя packer build создал голден имидж в reddit-base


## ДЗ №5 со *  

- Создан immutable шаблон на основе reddit-base — immutable.json
- Создан unit файл systemd для старта puma http server - files/puma.service 
- Создан скрипт для установки приложени и его зависимостей — files/install_puma.sh  
- Создан скрипт для создания immutable инстанса reddit-app использую имидж из reddit-full  — config-scripts/create-reddit-vm.sh

