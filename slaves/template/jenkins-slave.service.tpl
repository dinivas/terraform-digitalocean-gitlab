[Unit]
Description=Jenkins JNLP Slave
Wants=network.target
After=network.target

[Service]
EnvironmentFile=/etc/default/jenkins-slave
ExecStart=/usr/bin/java -jar /var/run/jenkins/slave.jar -jnlpUrl http://${jenkins_master_url}:8080/computer/${jenkins_node_name}/slave-agent.jnlp -secret $JENKINS_SLAVE_SECRET
User=jenkins
Group=jenkins
PermissionsStartOnly=true
Restart=always
LimitNOFILE=8192
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target