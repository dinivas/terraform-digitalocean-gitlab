#cloud-config
# vim: syntax=yaml

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
