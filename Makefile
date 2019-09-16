## Argument Variables ##

CPUS := $(shell nproc)
MEMORY := 10000
DEVICE := crosshatch
BACKEND := local
CHANNEL := beta
BUILD := user
FLAVOR := aosp

## Default Target ##

.DEFAULT_GOAL := default
.PHONY: default
default: fetch keys build release

## Primary Targets ##

.PHONY: fetch
fetch: submodule-update
	mkdir -p keys build/base build/release build/external
	$(contain) fetch

.PHONY: keys
keys: tools entropy
	$(contain) keys

.PHONY: build
build: machine image tools
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
mrproper:
	rm -rf build


## Secondary Targets ##

.PHONY: image
image:
	$(docker) build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t $(image) $(PWD)

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
	$(contain) shell

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


## VM Management ##

.PHONY: machine-start
machine-start: machine-install machine-create
	$(docker_machine) start $(FLAVOR)-$(BACKEND)

.PHONY: machine-stop
machine-stop:
	$(docker_machine) stop

.PHONY: machine-install
machine-install:
	# wget docker-machine & hash check here

.PHONY: machine-create
machine-create: machine-install
	$(docker_machine) create --driver $(BACKEND) $(FLAVOR)-$(BACKEND)

.PHONY: machine-shell
machine-shell:
	$(docker_machine) shell

## VM Bootstrapping ##

ifeq ($(BACKEND),local)

executables = docker
docker := docker
contain = $(contain_local)
machine:

else ifeq ($(BACKEND),virtualbox)

export VIRTUALBOX_SHARE_FOLDER="$(HOME):$(HOME)"

executables = docker-machine ssh
docker := $(docker_machine) ssh $(FLAVOR)-$(BACKEND) docker
contain = $(contain_local)
machine: machine-start

endif
check_executables := $(foreach exec,$(executables),\$(if \
	$(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

userid = $(shell id -u)
groupid = $(shell id -g)
image = "hashbang/aosp-build:latest"
contain_local := \
	$(docker) run -it --rm -h "aosp-build-$(FlAVOR)" \
		-v $(PWD)/build/base:/home/build/base \
		-v $(PWD)/build/release:/home/build/release \
		-v $(PWD)/build/external:/home/build/external \
		-v $(PWD)/keys:/home/build/keys \
		-v $(PWD)/scripts:/home/build/scripts \
		-v $(PWD)/config:/home/build/config \
		-v $(PWD)/patches:/home/build/patches \
		-u $(userid):$(groupid) \
		-e DEVICE=$(DEVICE) \
		--cpus $(CPUS) \
		$(image)
contain_remote := \
	$(docker) run -it --rm -h "aosp-build-$(FLAVOR)" \
		-v $(PWD)/build/release:/home/build/release \
		-v $(PWD)/keys:/home/build/keys \
		-v $(PWD)/scripts:/home/build/scripts \
		-v $(PWD)/config:/home/build/config \
		-v $(PWD)/patches:/home/build/patches \
		-u $(userid):$(groupid) \
		-e DEVICE=$(DEVICE) \
		$(image)

docker_machine := \
	docker-machine \
		--storage-path "${PWD}/build/machine"
