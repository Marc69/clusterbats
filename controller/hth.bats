#!/user/env/bin/bats

CONFIG=$(</trinity/site).cfg
source ${CONFIG} > /dev/null

@test "Setup switch" {
  for i in {1..5}; do
     sleep 1
  done
  chtab node=switch hosts.ip=${SWITCH}  #10.141.253.1

  echo "${SWITCH_TABLE}" > /tmp/switch.csv
  tabrestore /tmp/switch.csv

  makehosts switch
  makedns switch > /dev/null 2>&1 || true
  ping -c 1 switch
}


@test "Setup nodes" {
  nodeadd ${NODES} groups=compute
  makehosts compute
  makedns compute > /dev/null || true

  export CONTAINERS=${NODES/node/c}
  nodeadd $CONTAINERS groups=vc-a,hw-default

  makehosts vc-a 
  makedns ${CONTAINERS} > /dev/null 2>&1 || true
}


