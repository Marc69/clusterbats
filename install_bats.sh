#!/bin/bash

git clone https://github.com/sstephenson/bats.git && bats/install.sh ../.local/bin
pip install python-hostlist
pip install httpie 

