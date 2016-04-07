CONFIG=/root/clusterbats/controller/config/$(</trinity/site).cfg
source ${CONFIG}
CONTAINERS=${NODES//node/c}

expand() {
    hostlist -e "$@"
}

debug() {
    echo "# $@" >&3
}

