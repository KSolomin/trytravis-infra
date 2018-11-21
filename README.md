# KSolomin_infra
KSolomin Infra repository

Build status: [![Build Status](https://travis-ci.com/KSolomin/trytravis-infra.svg?branch=ansible-3)](https://travis-ci.com/KSolomin/trytravis-infra)

Домашнее задание 10:

1. Dynamic inventory для двух окружений настроен через утилиту terraform-inventory и скрипт pull_inventory.sh: при применении ansible плейбуков мы дергаем state нужного окружения с backend'a.

2. Для задания ** установили на рабочую машину trytravis, создали тестовый репозиторий для него, в файле .travis.yml определили дополнительные проверки нашего инфраструктурного кода (прогон линтеров, валидация кода и т.д.). Добавили бейджик о статусе билда.

Домашнее задание 9:

1. В рамках задания написали несколько плейбуков со сценариями, поработали с различными модулями, хендлерами; научились пользоваться j2 шаблонами и тегами. Научились деплоить приложение непосредственно ansible'ом.

2. Создали новые образы VM с помощью packer. На этот раз мы пользовались ansible provisioners (вместо shell), то есть написали два плейбука - для настройки reddit-app и reddit-db инстанса.

3. В рамках задания со * заимплементили dynamic inventory для ansible. Для этого мы: 
  a) Установили на локальную машину terraform-inventory (https://github.com/adammck/terraform-inventory).
  б) Написали скрипт pull_inventory.sh - скрипт вызывается в ansible.cfg и выполняет terraform state pull из бекенда в локальный файл. Затем из этого файла terraform-inventory подгружает хосты.

  Надо признать, что у такого подхода есть минусы: у нас в скрипте захардкожено, что мы используем окружение stage. Если потребуется работать с prod, нам придется либо явно указать это в скрипте, либо изменить структуру инфраструктурного репозитория.

Домашнее задание 8:

1. После удаления с хоста склонированного репозитория вывод плейбука отличается:

appserver                  : ok=2    changed=1    unreachable=0    failed=0

Т.е. Ансибл сообщает, что произвел изменения на хосте.

2. В репозиторий добавлен inventory.json и для его использования слегка изменен ansible.cfg. Вывод ansible all -m ping:

appserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

Домашнее задание 7:

1. С подключенном к terraform удаленном бэкендом и одновременном применении конфигурации наблюдается ошибка, так как state файл заблокирован.

2. Provisioners описаны в modules/app/main.tf и modules/db/main.tf. Для database инстанса в провижинге выполняется обновление конфигурации mongodb (нужно убрать или перезаписать bindIp в конфиге) и ее перезапуск. Для app инстанса нам надо указать в puma service IP адрес сервера базы данных, его мы получаем из outputs db module и вставляем в сервис используя template_file.

Домашнее задание 6:

1. При добавлении ssh-ключа appuser_web через веб-интерфейс появляется следующая проблема: каждый вызов terraform apply будет затирать этот ключ, так как его нет в описании ресурсов в terraform'е. Таким образом, нам надо либо описать этот ключ в terraform, либо пользоваться исключительно веб-интерфейсом для описания проектных ssh ключей.

2. При использовании балансировщика и двух инстансов с приложением (как описано в задании) проблем несколько:
a) У каждого инстанса своя Mongo DB, а это значит что конечному юзеру балансер будет рандомно отдавать либо один контент, либо другой. База данных должна быть уникальна, либо нам надо настраивать в разу более сложную схему работы с несколькими базами.
б) Много копипасты и код не реюзабельный, плохо масштабируется. Если захотим третий инстанс, придется вручную в коде дописывать всю информацию про "reddit-app3", и т.д.

Домашнее задание 4:

testapp_IP = 35.240.75.150
testapp_port = 9292

1. Команда для запуска инстанса и передачи ему локального startup скрипта:

gcloud compute instances create reddit-app --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --restart-on-failure --metadata-from-file startup-script=<путь до скрипта>/KSolomin_infra/startup.sh

2. Через startup-script-url сделать почему-то не получилось:

gcloud compute instances create reddit-app --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --restart-on-failure --metadata-from-file startup-script-url=gs://my-script-bucket/startup.sh

ERROR: (gcloud.compute.instances.create) Unable to read file [gs://my-script-bucket/startup.sh]: [Errno 2] No such file or directory: 'gs://my-script-bucket/startup.sh'

Бакет публичный. Та же ошибка возникла при указании ссылки на гист.

3. Создать правило для файрволла с помощью gcloud можно так:

gcloud compute firewall-rules create default-puma-server --target-tags=puma-server --allow tcp:9292 

Домашнее задание 3:

bastion_IP = 35.210.55.204
someinternalhost_IP = 10.132.0.3

1. Подключение к внутреннему хосту через Bastion в одну строчку:

ssh -A -tt appuser@35.210.55.204 ssh 10.132.0.3
или так:
ssh -o ProxyCommand='ssh -W %h:%p appuser@35.210.55.204' appuser@10.132.0.3

2. Подключение из консоли при помощи команды вида "ssh someinternalhost"
Так понимаю, нужно тоже использовать опцию ProxyCommand и ssh с ключом -W, но на этот раз указывать их в конфиге ssh. У меня получился такой файл:

cat ~/.ssh/config 
Host bastion
  HostName 35.210.55.204 
  User appuser
  ForwardAgent yes

Host someinternalhost
  HostName 10.132.0.3
  User appuser
  ProxyCommand ssh bastion -W %h:%p

Теперь подключаться можно проще:

ssh someinternalhost
Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.15.0-1021-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

Get cloud support with Ubuntu Advantage Cloud Guest:
http://www.ubuntu.com/business/services/cloud
This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

0 packages can be updated.
0 updates are security updates.

Last login: Fri Oct 12 19:30:40 2018 from 10.132.0.2
appuser@someinternalhost:~$

3. VPN поднят на bastion хосте. Подключиться к VPN можно используя файл конфигурации из репозитория. SSL сертификат от Let's Encrypt установлен на доменное имя "35.210.55.204.sslip.io", проверить можно обратившись к панели управления VPN по HTTPS:
https://35.210.55.204.sslip.io/#/
