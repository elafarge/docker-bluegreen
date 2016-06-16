Blue/Green deployments with HAProxy, Docker and `docker-compose`
================================================================

Introduction
------------

This repository is a proof-of-concept for Blue/Green deployments with HAProxy,
Docker and `docker-compose`.
It's mostly an experiment, for Blue/Green deployments at scale, there's already
an interesting amount of solutions. For instance, [kubernetes](http://kubernetes.io/),
[docker-swarm](https://docs.docker.com/swarm/) and the good old [fleet](https://github.com/coreos/fleet).

However, theses solutions take some time (weeks at least) to set up if you have
an already existing infrastructure. In the meantime, blue/green deployments with
Docker can be a good replacement for blue/green deployments consisting in
spawning/killing instances in the cloud: they run much much faster
(approximately 300x faster :) ) and don't imply tweaking autoscaling-groups,
load-balancersor DNS configuration.

Getting Started
---------------

The best way to get started is to spawn the `sample_service` included in the
repo. For that, one would just run:

```shell
docker-compose up --build
```

It will start an HAProxy container (bound to the hosts network) listening on
port 8000 and two instances of our `sample_service` a blue and a green one.

You can alter the code of `sample_service.go` (change `hello` to `ola` for
instance) and then run `./deploy_blue_green.sh`. You'll see your new image being
built and you application be updated in a blue/green way :)

A bit more interesting maybe, put a very long `time.Sleep` at the beginning of
the `main()` function of `sample_service.go`, so that your service never really
starts and deploy the new version of your code.

You'll see that HAProxy won't call your `blue` instance this it doesn't pass
HAProxy's health check... even better, you'll have the deployment script fail.
If it runs on Jenkins, TravisCI or whatever, you won't miss the red build.

General Usage
-------------

To be written (deploying images hosted on DockerHub, in-depth explanation about
how this setup works, how to monitor HAProxy and - more important - a beautiful
schema.

TODO
----
  * Sort of unit test the script's behaviour
  * Implement a rollback feature (ultimately this one would remove images that
    don't start from DockerHub or at least make sure the `latest` tag isn't
    pointing to one of them).

Authors
-------
  * Étienne Lafarge <etienne_dot_lafarge__at__gmail_dot_com>

