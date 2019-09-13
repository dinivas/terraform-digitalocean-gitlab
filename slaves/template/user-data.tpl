#cloud-config
# vim: syntax=yaml
groups:
  - jenkins
# users: #Cloud init user creation does'nt work well on centos
#   - name: jenkins
#     groups: jenkins
packages:
  - java-1.8.0-openjdk
runcmd:
  - [ useradd, -g, jenkins, jenkins]
  - [ mkdir, -p, /var/run/jenkins/]
  - [ wget, "http://${jenkins_master_url}:8080/jnlpJars/slave.jar", -O, /var/run/jenkins/slave.jar ]
