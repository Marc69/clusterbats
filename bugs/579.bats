load ../clusterbats/configuration

@test "#579 docker logs: nslcd entered FATAL state" {
  for NODE in ${ALL_NODES}; do
    if ! ssh ${NODE} docker exec trinity ps -ef | grep nslcd; then
      echo "nslcd not running on ${NODE}"; exit 1;
    fi
  done
}

