#!/bin/sh

# Remote create the agent
curl -X POST -u ${jenkins_master_username}:${jenkins_master_password} --data-urlencode "script=$(< /var/run/jenkins/add_slave.groovy)" http://${jenkins_master_url}:8080/scriptText

touch /etc/default/jenkins-slave

# Dump slave secret in env file
cmd=(curl -s -u ${jenkins_master_username}:${jenkins_master_password} http://${jenkins_master_url}:8080/computer/${jenkins_node_name}/slave-agent.jnlp)
jenkins_response=$("${cmd[@]}")
jenkins_secret=$(echo $jenkins_response | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
echo "JENKINS_SLAVE_SECRET=$jenkins_secret" > /etc/default/jenkins-slave