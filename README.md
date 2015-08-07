# clusterbats
Test procedure automation for trinity installations

## Instructions
On controller node (test of controller installation):

1) yum -y install git 

2) git clone https://github.com/clustervision/clusterbats

3) git clone https://github.com/sstephenson/bats

4) ./bats/install.sh /usr/local

5) cd clusterbats

6) bats t1.1.bats
