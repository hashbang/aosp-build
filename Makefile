## Argument Variables ##

CPUS := $(shell nproc)
MEMORY := 10000
DISK := 300000
DEVICE := crosshatch
BACKEND := local
CHANNEL := beta
BUILD := user
FLAVOR := aosp
IMAGE := hashbang/aosp-build:latest
NAME := aosp-build-$(FLAVOR)-$(BACKEND)

-include $(PWD)/config/env/$(BACKEND).env

## Default Target ##

.DEFAULT_GOAL := default
.PHONY: default
default: machine image fetch keys build release


## Primary Targets ##

.PHONY: fetch
fetch: submodule-update machine
	mkdir -p config/keys build/base release build/external
	$(contain) fetch

.PHONY: keys
keys: tools entropy
	$(contain) keys

.PHONY: build
build: image tools
	$(contain) build

.PHONY: release
release: tools
	$(contain) release

.PHONY: publish
publish:
	$(contain) publish

.PHONY: clean
clean: image
	$(contain) clean

.PHONY: mrproper
mrproper: machine-delete
	rm -rf build


## Secondary Targets ##

.PHONY: image
image: machine
	$(docker) build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t $(IMAGE) \
		-f $(PWD)/config/container/Dockerfile \
		$(PWD)

.PHONY: entropy
entropy:
	$(contain) entropy

.PHONY: tools
tools:
	$(contain) tools

.PHONY: vendor
vendor: tools
	$(contain) build-vendor

.PHONY: chromium
chromium: tools
	$(contain) build-chromium

.PHONY: kernel
kernel: tools
	$(contain) build-kernel


## Development ##

.PHONY: latest
latest: config submodule-latest fetch

.PHONY: manifest
manifest:
	$(contain) manifest

.PHONY: config
config: manifest
	$(contain) config

.PHONY: test-repro
test-repro:
	$(contain) test-repro

.PHONY: test
test: test-repro

.PHONY: patches
patches:
	@$(contain) bash -c "cd base; repo diff -u"

.PHONY: shell
shell:
	$(docker) inspect "$(NAME)" \
	&& $(docker) exec --interactive --tty "$(NAME)" shell \
	|| $(contain) shell

.PHONY: monitor
monitor:
	$(docker) inspect "$(NAME)" \
	&& $(docker) exec --interactive --tty "$(NAME)" htop

.PHONY: install
install: tools
	@scripts/flash


## Source Mangement ##

.PHONY: submodule-update
submodule-update:
	git submodule update --init --recursive

.PHONY: submodule-latest
submodule-latest:
	git submodule foreach 'git checkout master && git pull'

## Storage Bootstrapping ##

.PHONY: storage-digitalocean
storage-digitalocean:
	$(docker) volume ls | grep $(NAME) \
	||( $(docker) plugin install \
			--disable-content-trust	false \
			rexray/dobs \
			DOBS_REGION=$(DIGITALOCEAN_REGION) \
			DOBS_TOKEN=$(DIGITALOCEAN_TOKEN) \
		&& $(docker) volume create \
			--driver rexray/dobs \
			--opt=size=$(DISK) \
			--name=$(NAME)
	)

.PHONY: storage-local
storage-local:
	$(docker) volume ls | grep $(NAME) \
	|| $(docker) volume create \
		--driver local \
		--opt type=none \
		--opt o=bind \
		--opt device=$(PWD)/build \
		$(NAME)


## VM Management ##

.PHONY: machine-start
machine-start: machine-install machine-create machine-date
	$(docker_machine) status $(NAME) \
	|| $(docker_machine) start $(NAME)

.PHONY: machine-sync
machine-sync:
	$(docker_machine) scp -r -d config/ $(NAME):$(PWD)/config/

.PHONY: machine-shell
machine-shell:
	$(docker_machine) ssh $(NAME)

.PHONY: machine-stop
machine-stop:
	$(docker_machine) stop $(NAME)

.PHONY: machine-delete
machine-delete:
	$(docker_machine) rm $(NAME)

.PHONY: machine-date
machine-date:
	$(docker_machine) ssh $(NAME) \
		"sudo date -s @$(shell date +%s)"

.PHONY: machine-create
machine-create: machine-install
	$(docker_machine) status $(NAME) \
	||( $(docker_machine) create \
			--driver $(BACKEND) \
			$(docker_machine_create_flags) \
			$(NAME) \
	)

.PHONY: machine-install
machine-install:
	# wget docker-machine & hash check here


## VM Bootstrapping ##

ifeq ($(BACKEND),local)

executables = docker
docker = docker
machine:
storage_flags = --volume $(PWD)/build/:/home/build/build/
env_flags =

else ifeq ($(BACKEND),virtualbox)

executables = docker-machine ssh virtualbox
docker = $(docker_machine) ssh $(NAME) -t docker
machine: machine-start storage-local
storage_flags = --volume $(NAME):/home/build/build/
env_flags =
docker_machine_create_flags = \
	--virtualbox-share-folder="$(PWD):$(PWD)" \
	--virtualbox-disk-size="$(DISK)" \
	--virtualbox-memory="$(MEMORY)" \
	--virtualbox-cpu-count="$(CPUS)"

else ifeq ($(BACKEND),digitalocean)

executables = docker-machine ssh
docker = $(docker_machine) ssh $(NAME) -t docker
machine: machine-start storage-digitalocean machine-sync
storage_flags = --volume $(NAME):/home/build/build/
storage_flags =
env_flags = --env-file $(PWD)/config/env/digitalocean.env
docker_machine_create_flags = \
	--digitalocean-access-token=$(DIGITALOCEAN_TOKEN) \
	--digitalocean-region=$(DIGITALOCEAN_REGION) \
	--digitalocean-image=$(DIGITALOCEAN_IMAGE) \
	--digitalocean-size=$(DIGITALOCEAN_SIZE)

endif

userid = $(shell id -u)
groupid = $(shell id -g)
docker_machine = docker-machine --storage-path "${PWD}/build/machine"
contain := \
	$(docker) run \
		--rm \
		--tty \
		--interactive \
		--name "$(NAME)" \
		--hostname "$(NAME)" \
		--user $(userid):$(groupid) \
		--env DEVICE=$(DEVICE) \
		--security-opt seccomp=unconfined \
		--volume $(PWD)/config:/home/build/config \
		--volume $(PWD)/release:/home/build/release \
		$(storage_flags) \
		$(IMAGE)


## Required Binary Check ##

check_executables := $(foreach exec,$(executables),\$(if \
	$(shell which $(exec)),some string,$(error "No $(exec) in PATH")))
