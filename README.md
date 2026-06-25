# Nextcloud OCI

Container images of Nextcloud, a safe home for all your data.

## Goal

To provide a Kubernetes-friendly, read-only capable and relatively slim image.
In order to render video thumbnails, `ffmpeg` is included also.

## Images

Images are available on [Quay](https://quay.io/repository/flakybitnet/nextcloud-server), [GHCR](https://github.com/flakybitnet/nextcloud-docker/pkgs/container/nextcloud-server), [AWS](https://gallery.ecr.aws/flakybitnet/nextcloud/server) and [GitLab](https://gitlab.flakybit.net/fb/nextcloud/server-oci/container_registry) registries.

## Usage

Initialize first:

```
$ podman run -d -p 8080:80 --read-only --entrypoint=/bin/nc/init.sh -v config:/var/www/html/config -v data:/var/www/html/data quay.io/flakybitnet/nextcloud-server:<version>
$ docker run -d -p 8080:80 --read-only --entrypoint=/bin/nc/init.sh -v config:/var/www/html/config -v data:/var/www/html/data ghcr.io/flakybitnet/nextcloud-server:<version>
$ docker run -d -p 8080:80 --read-only --entrypoint=/bin/nc/init.sh -v config:/var/www/html/config -v data:/var/www/html/data public.ecr.aws/flakybitnet/nextcloud/server:<version>
$ docker run -d -p 8080:80 --read-only --entrypoint=/bin/nc/init.sh -v config:/var/www/html/config -v data:/var/www/html/data registry.flakybit.net/fb/nextcloud/server-oci:<version>
```

Then run application:

```
$ podman run -d -p 8080:80 --read-only -v config:/var/www/html/config -v data:/var/www/html/data quay.io/flakybitnet/nextcloud-server:<version>
$ docker run -d -p 8080:80 --read-only -v config:/var/www/html/config -v data:/var/www/html/data ghcr.io/flakybitnet/nextcloud-server:<version>
$ docker run -d -p 8080:80 --read-only -v config:/var/www/html/config -v data:/var/www/html/data public.ecr.aws/flakybitnet/nextcloud/server:<version>
$ docker run -d -p 8080:80 --read-only -v config:/var/www/html/config -v data:/var/www/html/data registry.flakybit.net/fb/nextcloud/server-oci:<version>
```

## Source

Source code are available at [GitLab](https://gitlab.flakybit.net/fb/nextcloud-oci) and mirrored to [GitHub](https://gitlab.flakybit.net/fb/nextcloud/server-oci).
