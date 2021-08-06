-   content: |
        [[runners]]
          name = "${gitlab_runner_description}"
          url = "${gitlab_runner_group_gitlab_url}"
          token = "${gitlab_runner_group_gitlab_token}"
          executor = "${gitlab_runner_group_executor}"
          builds_dir = "/tmp/builds"
          cache_dir = "/cache"
          [runners.custom_build_dir]
          [runners.cache]
            [runners.cache.s3]
            [runners.cache.gcs]
            [runners.cache.azure]
          [runners.docker]
            tls_verify = false
            image = "${gitlab_runner_group_docker_image}"
            pull_policy = ["if-not-present"]
            privileged = true
            disable_entrypoint_overwrite = false
            oom_kill_disable = false
            disable_cache = false
            volumes = ["/cache:/cache", "/var/run/docker.sock:/var/run/docker.sock", "/tmp/builds:/tmp/builds"]
            shm_size = 0
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
        --docker-privileged true

    path: /etc/register-gitlab-runner.sh
    permissions: '755'

