load config/configuration

@test "2.2.1 Monitoring agent installed correctly on monitored nodes" {
   sshpass -p system ssh node002 check_mk_agent
}
