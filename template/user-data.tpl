#cloud-config
# vim: syntax=yaml

runcmd:
  - [ useradd, -g, jenkins, jenkins]
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
 %{ if jenkins_master_use_keycloak == "1" }
-   content: |
        import jenkins.model.*
        import hudson.security.*
        import org.jenkinsci.plugins.KeycloakSecurityRealm

        Jenkins.instance.setSecurityRealm(new KeycloakSecurityRealm())
        Jenkins.instance.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())

        def keycloakSecurityConfig = Jenkins.instance.getExtensionList('org.jenkinsci.plugins.KeycloakSecurityRealm$DescriptorImpl')[0]
        keycloakSecurityConfig.keycloakJson = '''
        {
            "realm": "${project_name}",
            "auth-server-url": "http://${jenkins_master_keycloak_host}/auth",
            "ssl-required": "external",
            "resource": "${jenkins_master_keycloak_client_id}",
            "public-client": true,
            "confidential-port": 0
        }
        '''
        keycloakSecurityConfig.keycloakValidate = true
        keycloakSecurityConfig.save()

    path: /var/lib/jenkins/init.groovy.d/setup_keycloak.groovy
    permissions: '755'
%{ endif }
-   content: |
        {"service":
            {"name": "${jenkins_master_name}",
            "tags": ["web"],
            "port": 8080
            }
        }

    owner: consul:bin
    path: /etc/consul/consul.d/jenkins-service.json
    permissions: '644'
 %{ if jenkins_master_register_exporter_to_consul == "1" }
-   content: |
        {"service":
            {"name": "jenkins_exporter",
            "tags": ["monitor"],
            "port": 9118
            }
        }

    owner: consul:bin
    path: /etc/consul/consul.d/jenkins_exporter-service.json
    permissions: '644'
%{ endif }
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