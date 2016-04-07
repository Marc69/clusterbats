#!/bin/bash

yum -y install git jq
git clone https://github.com/sstephenson/bats.git && bats/install.sh /usr/local
pip install python-hostlist
pip install httpie 

