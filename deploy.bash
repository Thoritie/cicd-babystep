#!/usr/bin/env bash

cd cicd-babystep
# sudo apt-get install python-virtualenv 

virtualenv flask-env
source flask-env/bin/activate
pip install Flask

python app.py
