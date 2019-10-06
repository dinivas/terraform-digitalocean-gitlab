#cloud-config
# vim: syntax=yaml

runcmd:
  - [ useradd, -g, jenkins, jenkins]
write_files:
 %{ if jenkins_master_use_keycloak == "1" }
-   content: |
        import jenkins.model.*
        import hudson.security.*
        import org.jenkinsci.plugins.KeycloakSecurityRealm

        Jenkins.instance.setSecurityRealm(new KeycloakSecurityRealm())
        Jenkins.instance.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())

        def keycloakSecurityConfig = Jenkins.instance.getExtensionList('org.jenkinsci.plugins.KeycloakSecurityRealm$DescriptorImpl')[0]
        keycloakSecurityConfig.keycloakJson = '''
        ${jenkins_master_keycloak_config}
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
