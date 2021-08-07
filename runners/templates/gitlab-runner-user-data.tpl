-   content: |
        listen_address = "${gitlab_runner_group_prometheus_listen_address}"
        concurrent = 1
        check_interval = 0

        [session_server]
          session_timeout = 1800
    path: /etc/gitlab-runner/config.toml
    permissions: '755'
-   content: |
        #!/bin/sh

        gitlab-runner register -n \
        --name "${gitlab_runner_description}" \
        --url ${gitlab_runner_group_gitlab_url} \
        --registration-token ${gitlab_runner_group_gitlab_token} \
        --executor ${gitlab_runner_group_executor} \
        --docker-image "${gitlab_runner_group_docker_image}" \
        --docker-privileged true \
        --cache-dir /cache \
        --docker-volumes '/cache:/cache' \
        --docker-volumes '/var/run/docker.sock:/var/run/docker.sock' \
        --docker-volumes '/tmp/builds:/tmp/builds' \
        --docker-pull-policy 'if-not-present'
        
        gitlab-runner restart

    path: /etc/register-gitlab-runner.sh
    permissions: '755'
-   content: |
        {"service":
            {"name": "gitlab-runner-exporter",
            "tags": ["monitor"],
            "port": 9252
            }
        }

    owner: consul:bin
    path: /etc/consul/consul.d/gitlab-runner_exporter-service.json
    permissions: '644'

