#!/usr/bin/env bats
load config/configuration
@test "2.2.0.0 RSA installation is successfull" {
      source /xcatpost/cv_install_rsa | grep -q "Successfully built"
      domainname cluster
      source /xcatpost/cv_install_mail
      python /xcatpost/cv_install_moncon
  }
@test "2.2.0 Monitoring agent installed correctly on monitored nodes" {
  for NODE in $(expand ${NODES}) ; do
    sshpass -p system ssh $NODE check_mk_agent
  done
 }
@test "2.2.1.0 OMD service is running in the container" {
 docker ps | grep omd | grep -i up
 }
@test "2.2.2 We can launch the monitoring web interface" {
 wget -q --user admin --password system http://controller.cluster:5003/monitoring
 }
