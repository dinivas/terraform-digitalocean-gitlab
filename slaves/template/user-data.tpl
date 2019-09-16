#cloud-config
# vim: syntax=yaml
groups:
  - jenkins
# users: #Cloud init user creation does'nt work well on centos
#   - name: jenkins
#     groups: jenkins
runcmd:
  - [ useradd, -g, jenkins, jenkins]
  - [ mkdir, -p, /var/run/jenkins/]
  - [ sh, -c, /etc/register-slave.sh]
write_files:
-   content: |
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
    path: /etc/systemd/system/jenkins-slave.service
    permissions: '755'
-   content: |
        import hudson.model.Node.Mode
        import hudson.slaves.*
        import jenkins.model.Jenkins
        DumbSlave dumb = new DumbSlave(
                "${jenkins_node_name}",
                "/home/jenkins",
                new JNLPLauncher()
                )
        dumb.setNodeDescription("${jenkins_slave_description }")
        dumb.setNumExecutors(${jenkins_slave_nb_executor })
        dumb.setLabelString("${jenkins_slave_labels}")
        dumb.setMode(Mode.NORMAL)
        dumb.setRetentionStrategy(RetentionStrategy.INSTANCE)
        Jenkins.instance.addNode(dumb)
        println "Agent ${jenkins_node_name} added"
    path: /var/run/jenkins/add_slave.groovy
    permissions: '755'
-   content: |
        #!/bin/sh

        # Wait for master to be accessible, used when master and slave are created at the same time
        timeout ${jenkins_slave_wait_for_master_timeout} bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 5; done' ${jenkins_master_url} 8080

        # Download slave.jar from master
        wget "http://${jenkins_master_url}:8080/jnlpJars/slave.jar" -O /var/run/jenkins/slave.jar

        # Remote create the agent
        curl -X POST -u ${jenkins_master_username}:${jenkins_master_password} --data-urlencode "script=$(< /var/run/jenkins/add_slave.groovy)" http://${jenkins_master_url}:8080/scriptText

        touch /etc/default/jenkins-slave

        # Dump slave secret in env file
        cmd=(curl -s -u ${jenkins_master_username}:${jenkins_master_password} http://${jenkins_master_url}:8080/computer/${jenkins_node_name}/slave-agent.jnlp)
        jenkins_response=$("$${cmd[@]}")
        jenkins_secret=$(echo $jenkins_response | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
        echo "JENKINS_SLAVE_SECRET=$jenkins_secret" > /etc/default/jenkins-slave

        # Enable and start service
        systemctl enable jenkins-slave
        systemctl start jenkins-slave
    path: /etc/register-slave.sh
    permissions: '755'
