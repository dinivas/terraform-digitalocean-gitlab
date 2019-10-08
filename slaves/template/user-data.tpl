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
  - [ sh, -c, /etc/configure-consul.sh]
write_files:
-   content: |
        {
          "addresses": {
              "dns": "0.0.0.0",
              "grpc": "0.0.0.0",
              "http": "0.0.0.0",
              "https": "0.0.0.0"
          },
          "advertise_addr": "",
          "advertise_addr_wan": "",
          "bind_addr": "0.0.0.0",
          "bootstrap": false,
          %{ if consul_agent_mode == "server" }
          "bootstrap_expect": ${consul_server_count},
          %{ endif }
          "client_addr": "0.0.0.0",
          "data_dir": "/var/consul",
          "datacenter": "${consul_cluster_datacenter}",
          "disable_update_check": false,
          "domain": "${consul_cluster_domain}",
          "enable_local_script_checks": true,
          "enable_script_checks": false,
          "log_file": "/var/log/consul/consul.log",
          "log_level": "INFO",
          "log_rotate_bytes": 0,
          "log_rotate_duration": "24h",
          "log_rotate_max_files": 0,
          "node_name": "",
          "performance": {
              "leave_drain_time": "5s",
              "raft_multiplier": 1,
              "rpc_hold_timeout": "7s"
          },
          "ports": {
              "dns": 8600,
              "grpc": -1,
              "http": 8500,
              "https": -1,
              "serf_lan": 8301,
              "serf_wan": 8302,
              "server": 8300
          },
          "raft_protocol": 3,
          "retry_interval": "30s",
          "retry_interval_wan": "30s",
          "retry_join": ["provider=os tag_key=consul_cluster_name tag_value=${consul_cluster_name} domain_name=${os_auth_domain_name} user_name=${os_auth_username} password=${os_auth_password} auth_url=${os_auth_url} project_id=${os_project_id}"],
          "retry_max": 0,
          "retry_max_wan": 0,
          "server": %{ if consul_agent_mode == "server" }true%{ else }false%{ endif },
          "translate_wan_addrs": false,
          "ui": %{ if consul_agent_mode == "server" }true%{ else }false%{ endif },
          "disable_host_node_id": true
        }

    owner: consul:bin
    path: /etc/consul/config.json
    permissions: '644'
-   content: |
        [Unit]
        Description=Jenkins JNLP Slave
        Wants=network.target
        After=network.target

        [Service]
        EnvironmentFile=/etc/default/jenkins-slave
        ExecStart=/usr/bin/java -jar /var/run/jenkins/slave.jar -jnlpUrl ${jenkins_master_scheme}://${jenkins_master_host}:${jenkins_master_port}/computer/${jenkins_node_name}/slave-agent.jnlp -secret $JENKINS_SLAVE_SECRET
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

        # Wait for master to be accessible (http: 200), used when master and slave are created at the same time
        timeout ${jenkins_slave_wait_for_master_timeout} bash -c 'while [[ "$(curl -s -o /dev/null -w ''%%{http_code}'' ${jenkins_master_host}:${jenkins_master_port})" != "200" ]]; do sleep 5; done' || false

        # Download slave.jar from master
        wget -q "${jenkins_master_scheme}://${jenkins_master_host}:${jenkins_master_port}/jnlpJars/slave.jar" -O /var/run/jenkins/slave.jar

        # Remote create the agent using username & password
        curl -X POST -u ${jenkins_master_username}:${jenkins_master_password} --data-urlencode "script=$(< /var/run/jenkins/add_slave.groovy)" ${jenkins_master_scheme}://${jenkins_master_host}:${jenkins_master_port}/scriptText

        # Remote create the agent using keycloak token
        # kctoken_query=(curl -s -d "client_id=jenkins" -d "username=admin" -d "password=admin" -d "grant_type=password" http://d3c0fb86.ngrok.io/auth/realms/dnv/protocol/openid-connect/token )
        # kctoken=$("$${kctoken_query[@]}" | jq -r ".access_token" -)
        # curl -H "Authorisation: Bearer $kctoken" -X POST --data-urlencode "script=$(< /var/run/jenkins/add_slave.groovy)" ${jenkins_master_scheme}://${jenkins_master_host}:${jenkins_master_port}/scriptText

        touch /etc/default/jenkins-slave

        # Dump slave secret in env file
        cmd=(curl -s -u ${jenkins_master_username}:${jenkins_master_password} ${jenkins_master_scheme}://${jenkins_master_host}:${jenkins_master_port}/computer/${jenkins_node_name}/slave-agent.jnlp)
        jenkins_response=$("$${cmd[@]}")
        jenkins_secret=$(echo $jenkins_response | sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")
        echo "JENKINS_SLAVE_SECRET=$jenkins_secret" > /etc/default/jenkins-slave

        # Enable and start service
        systemctl enable jenkins-slave
        systemctl start jenkins-slave
    path: /etc/register-slave.sh
    permissions: '755'
-   content: |
        #!/bin/sh

        sed -i '1inameserver 127.0.0.1' /etc/resolv.conf

        #Remove Consul existing datas
        chmod -R 755 /var/consul
        rm -R /var/consul/*

        instance_ip4=$(ip addr show dev eth0 | grep inet | awk '{print $2}' | head -1 | cut -d/ -f1)
        instance_hostname=$(hostname -s)

        echo " ===> Configuring Consul"
        # Update value in consul config.json
        tmp=$(mktemp)
        jq ".advertise_addr |= \"$instance_ip4\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json
        jq ".advertise_addr_wan |= \"$instance_ip4\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json
        jq ".node_name |= \"$instance_hostname\"" /etc/consul/config.json > "$tmp" && mv -f "$tmp" /etc/consul/config.json

        echo " ===> Restart Consul"
        systemctl restart consul

    path: /etc/configure-consul.sh
    permissions: '744'
