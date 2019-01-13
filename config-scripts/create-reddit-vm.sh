#!/bin/bash
# Создание VM в GCP на основе golden имиджа reddit-full
gcloud compute instances create reddit-app \
--boot-disk-size=10GB \
--image-family reddit-full \
--machine-type=g1-small \
--tags puma-server \
--restart-on-failure
