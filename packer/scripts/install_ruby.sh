#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

#Обновляем APT и устанавливаем Ruby и Bundler:
apt-get update
apt-get install -y ruby-full ruby-bundler build-essential

#Обновляем bundler
gem install bundler

