#!/bin/bash

source common.config

INDEX_SERVERS_COUNT=`wc -w <<< ${INDEX_SERVER}`

config() {
  :
}

umount() {
  # umount previous index
  local index_mount_dir=$1
  ssh $INDEX_SERVER "sudo umount ${index_mount_dir}/1_0"
}

mount() {
  # mount index
  local index_mount_dir=$1
  mkdir -p ${index_mount_dir}
  ssh ${INDEX_SERVER} "df -h"
  #ssh ${INDEX_SERVER} "${WEBSEARCH_HOME_DIR}/scripts/mount_generate_index_part.sh ${INDEX_SERVERS_COUNT} ${WEBSEARCH_HOME_DIR}/test_out/ ${INDEX_SERVER}"
  #ssh ${INDEX_SERVER} "bash -s" -- < mount_generate_index_part.sh ${INDEXES_COUNT} ${INDEX_SERVERS_COUNT} ${WEBSEARCH_HOME_DIR}/test_out/ ${INDEX_SERVER}
  ssh ${INDEX_SERVER} "bash -s" -- < mount_generate_index_part.sh ${INDEXES_COUNT} 2 ${WEBSEARCH_HOME_DIR}/test_out/ ${INDEX_SERVER} node1
  ssh ${INDEX_SERVER} "df -h"
}

start() {
  local index_mount_dir=$WEBSEARCH_HOME_DIR/test_out
  
  umount ${index_mount_dir}
  mount ${index_mount_dir}

  # defines how many threads per index process usually same as the number of clients for close loop experiments
  local handlers=${INDEX_THREADS}
  ssh ${INDEX_SERVER} "sed -i '905s/<value>.*<\/value>/<value>'\"${handlers}\"'<\/value>/' ${WEBSEARCH_HOME_DIR}\"/dis_search/conf/nutch-default.xml\"; exit"

  echo "Starting index server ${INDEX_SERVER}..."
  ssh ${INDEX_SERVER} "
    cd ${WEBSEARCH_HOME_DIR}/dis_search/logs;
    rm hadoop.log;
    export JAVA_HOME=${WEBSEARCH_HOME_DIR}/jdk1.7.0_11;
    ${WEBSEARCH_HOME_DIR}/dis_search/bin/nutch search_server 8890 ${index_mount_dir}/1_0 &> /dev/null & exit"
  #sleep 30
  while ! nc -z localhost 8890; do
  sleep 0.1 # wait for 1/10 of the second before check again
  done
  echo "Starting index server ${INDEX_SERVER}...DONE"
}

stop() {
  local username=$(whoami)
  echo "Stopping index server ${INDEX_SERVER}"
  ssh ${INDEX_SERVER} "pkill -f dis_search"
}

$@
