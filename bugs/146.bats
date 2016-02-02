load ../clusterbats/configuration

@test "#146 additional packages" {
  rpm -q strace tcpdum telnet minicom screen
}

