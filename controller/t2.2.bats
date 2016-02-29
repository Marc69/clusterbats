load config/configuration

@test "2.2.1 Monitoring agent installed correctly on monitored nodes" {
  for NODE in $(expand ${NODES}) ; do
    sshpass -p system ssh NODE check_mk_agent
  done
}
