#!/bin/bash

apt-get -y install git jq
git clone https://github.com/sstephenson/bats.git && bats/install.sh
pip install python-hostlist
pip install httpie 

