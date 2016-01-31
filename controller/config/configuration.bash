CONFIG=/root/clusterbats/controller/config/$(</trinity/site).cfg
source ${CONFIG}
CONTAINERS=${NODES/node/c}

expand() {
    lsdef "$@" | grep "Object name" | awk -F': ' '{print $2}'
}

debug() {
    echo "# $@" >&3
}

