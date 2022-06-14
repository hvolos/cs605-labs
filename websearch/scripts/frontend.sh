#!/bin/bash

source common.config

tomcat_instance_name() {
 if [ $i -eq 0 ]; then 
   echo "tomcat"
 else
   echo "tomcat"${i}
 fi
}

config() {
  local i=1
  local port
  local tomcat_instance_dir
  while [ $i -lt ${FRONTEND_INSTANCES_PER_SERVER} ];
  do
    tomcat_instance_dir=${WEBSEARCH_HOME_DIR}/"tomcat"${i}
    cp -r ${WEBSEARCH_HOME_DIR}/tomcat ${tomcat_instance_dir}
    ((http_port=8080+$i))
    ((ajp_port=8009+$i))
    ((redirect_port=8443+$i))
    ((server_port=8005+200+$i))
    sed -i "/Connector port=\"8080\" protocol=\"HTTP\/1\.1\"/ {n;n; /redirectPort=\"8443\"/ {s/redirectPort=\"8443\"/redirectPort=\"${redirect_port}\"/}}" ${tomcat_instance_dir}/conf/server.xml
    sed -i "s/Connector port=\"8080\" protocol=\"HTTP\/1\.1\"/Connector port=\"${http_port}\" protocol=\"HTTP\/1\.1\"/" ${tomcat_instance_dir}/conf/server.xml
    sed -i "s/Connector port=\"8009\" protocol=\"AJP\/1\.3\" redirectPort=\"8443\"/Connector port=\"${ajp_port}\" protocol=\"AJP\/1\.3\" redirectPort=\"${redirect_port}\"/" ${tomcat_instance_dir}/conf/server.xml
    sed -i "s/Server port=\"8005\" shutdown=\"SHUTDOWN\"/Server port=\"${server_port}\" shutdown=\"SHUTDOWN\"/" ${tomcat_instance_dir}/conf/server.xml
    ((i=i+1))	
  done
}

test_frontend() {
  local i=0
  local http_port
  while [ $i -lt ${FRONTEND_INSTANCES_PER_SERVER} ];
  do	
    echo "Test frontend server ${FRONTEND_SERVER} instance ${i}..."
    ((http_port=8080+$i))
    curl "${FRONTEND_SERVER}:${http_port}/onlyHits.jsp?query=google"
    echo "Test frontend server ${FRONTEND_SERVER} instance ${i}...DONE"
    ((i=i+1))	
  done  
}

start() {
  local i=0
  while [ $i -lt ${FRONTEND_INSTANCES_PER_SERVER} ];
  do
    echo "Starting frontend server ${FRONTEND_SERVER} instance ${i}..."
    
    local tomcat_instance_dir=${WEBSEARCH_HOME_DIR}/$(tomcat_instance_name $i)

    ssh $FRONTEND_SERVER "
      cd ${tomcat_instance_dir}/logs; 
      rm catalina.out;
      export JAVA_HOME=${WEBSEARCH_HOME_DIR}/jdk1.7.0_11; 
      ${tomcat_instance_dir}/bin/startup.sh &> /dev/null &  exit"
    
    ((i=i+1))
  done
  
  #sleep 20
  while ! nc -z localhost 8080; do sleep 0.1; done;

  i=0
  while [ $i -lt ${FRONTEND_INSTANCES_PER_SERVER} ];
  do
    echo "Starting frontend server ${FRONTEND_SERVER} instance ${i}...DONE"
    ((i=i+1))
  done

  test_frontend
}

stop() {
  local username=$(whoami)

  local i=0
  while [ $i -lt ${FRONTEND_INSTANCES_PER_SERVER} ];
  do
    echo "Stopping frontend server ${FRONTEND_SERVER} instance ${i}..."
    
    local tomcat_instance_dir=${WEBSEARCH_HOME_DIR}/$(tomcat_instance_name $i)
    ssh ${FRONTEND_SERVER} "ps aux | grep $(tomcat_instance_name $i) | grep -v grep | awk '{print \$2}' | xargs kill -9 2> /dev/null" 
    
    ((i=i+1))
  done
 
}

$@
