#!/bin/bash

#VERBOSE=-v

INVENTORY_FILE=hosts

SCRIPT_HOME="$(cd "$(dirname "$0")"; pwd)"

function frontend_hosts() {
  local inventory_file=$1
  awk -v TARGET=frontend -F ' *= *' '
    {
      if ($0 ~ /^\[.*\]$/) {
        gsub(/^\[|\]$/, "", $0)
        SECTION=$0
      } else if (SECTION==TARGET) {
        host_port=8080
        where_host = match($0, /^([A-Za-z0-9\-]*)/, arr_host)
        where_ansible_host = match($0, /ansible_host=([A-Za-z0-9\-]*)/, arr_ansible_host)
        where_socket = match($0, /socket=([0-9]*)/, arr_socket)
        if (where_socket != 0)
          host_port += arr_socket[1]
        if (where_ansible_host != 0)
          host = arr_ansible_host[1]
        else
          host = arr_host[1]
          printf "%s:%d\n", host, host_port
      }
    }
    ' ${inventory_file}
}

function config() {
  ansible-playbook ${VERBOSE} -i hosts ${SCRIPT_HOME}/ansible/frontend_config.yml
}

function start() {
  ansible-playbook ${VERBOSE} -i hosts ${SCRIPT_HOME}/ansible/frontend_start.yml
}

function stop() {
  ansible-playbook ${VERBOSE} -i hosts ${SCRIPT_HOME}/ansible/frontend_stop.yml
}

function test() {
  for frontend in $(frontend_hosts ${INVENTORY_FILE}); do
    echo "Test frontend server instance ${frontend}..."
    curl "${frontend}/onlyHits.jsp?query=google"
  done  
}

$@
