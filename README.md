[Kirby](https://getkirby.com) is a PHP-based flat-file content management system (CMS). Use the `Dockerfile` in this repo to build your own Kirby-ready Debian+Apache+PHP Docker image, like this:

    docker build \
        --build-arg TAG=8.1-apache-bullseye \
        --tag my-kirby-apache-development:8.1-apache-bullseye \
        https://github.com/dazzitcorp/kirby-apache-development.git#main

Note that there's no `docker pull`, no `git clone`, just `docker run`; `docker` will grab the `Dockerfile` directly from here and use it to build your very own (local) Docker image.

The first argument, `--build-arg`, chooses the [official Debian+Apache+PHP](https://hub.docker.com/_/php/) image your image will be based on. Looking at the [tags](https://github.com/docker-library/docs/blob/master/php/README.md#supported-tags-and-respective-dockerfile-links) available today, you can see there are quite a few to choose from:

* `8.1.7RC1-apache-bullseye`, `8.1-rc-apache-bullseye`, `8.1.7RC1-apache`, `8.1-rc-apache`
* `8.1.7RC1-apache-buster`, `8.1-rc-apache-buster`
`8.1.6-apache-bullseye`, `8.1-apache-bullseye`, `8-apache-bullseye`, `apache-bullseye`, `8.1.6-apache`, `8.1-apache`, `8-apache`, `apache`
* `8.1.6-apache-buster`, `8.1-apache-buster`, `8-apache-buster`, `apache-buster`
* `8.0.19-apache-bullseye`, `8.0-apache-bullseye`, `8.0.19-apache`, `8.0-apache`
* `8.0.19-apache-buster`, `8.0-apache-buster`
* `7.4.29-apache-bullseye`, `7.4-apache-bullseye`, `7-apache-bullseye`, `7.4.29-apache`, `7.4-apache`, `7-apache`
* `7.4.29-apache-buster`, `7.4-apache-buster`, `7-apache-buster`
* ...

If you don't set a `TAG` using `--build-arg` you'll get `apache` by default. `apache` which will give you the latest stable versions of Debian, Apache and PHP. (Well, no, not really. It will give you whatever the official Docker PHP guys decided to give you. :-)

Keep in mind that any and all tags you pick will use the exact same `Dockerfile`, the one sitting next to this `README`. Go too far into the future, or too far into the past, and something is bound to break!

Here's how to run the image you just created:

    docker run \
        -it \
        --publish 8080:80 \
        --rm \
        my-kirby-apache-development:8.1-apache-bullseye

Notice how the last parameter, `my-kirby-apache-development:8.1-apache-bullseye`, matches the `--tag` from the `build` you ran earlier.

(If you actually took the time to try that out, you'll be looking at Apache running in the foreground. Hit `ctrl+c` to stop it, and then `exit` the container.)

Use your new image to take Kirby for a spin. You're going to create a site called `mysite`. First, create a directory for it:

    mkdir mysite

(And don't `cd` into it.)

Then run `docker` again — but this time:

* bind the directory you just created to a directory in the container; and
* run `bash` to get a shell inside the container.

Like this:

    docker run \
        -it \
        --publish 8080:80 \
        --rm \
        --mount type=bind,source="$(shell pwd)/mysite",target=/var/www/html \
        my-kirby-apache-development:8.1-apache-bullseye \
        bash

I've used a `bash`-ism in my *host* shell, `$(shell pwd)`, to get the full path to the working directory. If you're using a different shell you'll probably need to do something else. Worst case, though, you can just enter the full path to the `mysite` directory yourself, oldschool; full (absolute) paths are a requirement for Docker binds.

Now that you have a shell, either install Kirby's StarterKit:

    composer create-project getkirby/starterkit  .

or, if you'd rather start from a clean slate, Kirby's PlainKit:

    composer create-project getkirby/plainkit  .

Your current directory, `.`, should be `/var/www/html`, Apache's `DocumentRoot`. That's the directory you start in when you run the container. It's *also* the directory you bound the `mysite` directory to. So: you're actually installing Kirby directly into your container's `DocumentRoot` directory. And your host's `mysite` directory. At the same time.

When the install is finished, run Apache in the container:

    apache2-foreground 

Once it's running, open a browser and head to `http://localhost:8080`. (`8080` is the port you published when you ran `docker`.) You should see Kirby's sample site. Go to `http://localhost:8080/panel` to create a user. Once you do you'll end up on Kirby's admin panel.

Nifty.

When you're finished, hit `ctrl-c` to stop Apache and `exit` the container.

## Ongoing Development

There are three nice things about this approach.

* First, you can choose your initial image yourself. In fact, you can choose as many as you like, and have as many local images as you like! (That's why the example above tagged the image you built with the same tag you were building *from* — so that you could tell them apart if you built more than one.)

* Second, you can reuse the image you built across multiple Kirby sites. At the same time. (I'm about to tell you a bit more about how I do that myself.)

* Third, you can edit your site's files in your host, using your favourite tools — even while your `docker` container is running and serving those files.

Here's a little more detail about my own environment.

I have a `Makefile` in the root of each project that looks a bit like this:

```
CONTAINER_NAME=mysite
CONTAINER_PORT=8082
IMAGE_NAME=kirby-apache-development
IMAGE_TAG=8.1-apache-bullseye
SITE_DIR=mysite

.PHONY: docker-attach
docker-attach:
    docker attach $(CONTAINER_NAME)

.PHONY: docker-kill
docker-kill:
    docker kill $(CONTAINER_NAME)

.PHONY: docker-run
docker-run:
    mkdir -p $(SITE_DIR)
    # Don't use "-t" to avoid SIGWINCH on attach (https://github.com/docker-library/httpd/issues/9).
    docker run -di --publish $(CONTAINER_PORT):80 --mount type=bind,source="$(shell pwd)/$(SITE_DIR)",target=/var/www/html --name $(CONTAINER_NAME) --rm $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: docker-run-shell
docker-run-shell:
    mkdir -p $(SITE_DIR)
    docker run -dit --publish $(CONTAINER_PORT):80 --mount type=bind,source="$(shell pwd)/$(SITE_DIR)",target=/var/www/html --name $(CONTAINER_NAME) --rm $(IMAGE_NAME):$(IMAGE_TAG) bash
```

The bodies of each `Makefile` are the same; I just change the values at the top.

* `CONTAINER_NAME` is the container's name. (I use the name of the site.)

* `CONTAINER_PORT` is the container's port. (I use a different port for each site.)

* `IMAGE_NAME` is the name of the image I built from the `Dockerfile`. (I use the repo I built from.)

* `IMAGE_TAG` is the tag of the image I built from the `Dockerfile`.  (I use the tag I built from.)

* `SITE_DIR` is the name of the subdirectory that contains the site. (I use a `PROJECT_DIR/SITE_DIR` structure. The `Makefile` is in `PROJECT_DIR`; Kirby is in `SITE_DIR`.)

That's the configuration. The usage is pretty straightforward, but here are a few quick notes.

* To birth a container, use `make docker-run`. Unlike the examples above, the `Makefile` detaches after running; you won't be left with a shell.

* To kill a container, use `make docker-kill`.

* If you want to monitor Apache, use `make docker-attach`.

* If you want to develop Kirby, use `make docker-shell`.

There really isn't much reason to pause (`docker stop`) or resume (`docker start`) these containers. There's nothing unique about them. Or in them. :-)