CONFIG=/root/clusterbats/controller/$(</trinity/site).cfg
source ${CONFIG}
CONTAINERS=${NODES/node/c}

expand() {
    lsdef "$@" | grep "Object name" | awk -F': ' '{print $2}'
}

