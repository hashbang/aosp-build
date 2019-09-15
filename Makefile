CPUS := "2"
device = ${DEVICE}
machine = ${MACHINE}
userid = $(shell id -u)
groupid = $(shell id -g)
image = "hashbang/aosp-build:latest"
contain := \
	mkdir -p keys build/base && \
	mkdir -p keys build/release && \
	mkdir -p keys build/external && \
	scripts/machine docker run -t --rm -h "android" \
		-v $(PWD)/build/base:/home/build/base \
		-v $(PWD)/build/release:/home/build/release \
		-v $(PWD)/build/external:/home/build/external \
		-v $(PWD)/keys:/home/build/keys \
		-v $(PWD)/scripts:/home/build/scripts \
		-v $(PWD)/config:/home/build/config \
		-v $(PWD)/patches:/home/build/patches \
		-u $(userid):$(groupid) \
		-e DEVICE=$(device) \
		--cpus $(CPUS) \
		$(image)

.DEFAULT_GOAL := default
.PHONY: default
default: build

.PHONY: image
image:
	@scripts/machine docker build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t $(image) $(PWD)

.PHONY: manifest
manifest:
	$(contain) manifest

.PHONY: config
config: manifest
	$(contain) config

.PHONY: fetch
fetch:
	mkdir -p build
	@$(contain) fetch

.PHONY: tools
tools:
	@$(contain) tools

.PHONY: random
random:
	mkdir -p $(PWD)/build
	test -f $(PWD)/build/.rnd || head -c 1G < /dev/urandom > $(PWD)/build/.rnd

.PHONY: keys
keys: tools
	@$(contain) keys

.PHONY: build
build: image tools
	@$(contain) build

.PHONY: kernel
kernel: tools
	@$(contain) build-kernel

.PHONY: vendor
vendor: tools
	@$(contain) build-vendor

.PHONY: chromium
chromium: tools
	@$(contain) build-chromium

.PHONY: release
release: tools
	mkdir -p build/release
	@$(contain) release

.PHONY: test-repro
test-repro:
	@$(contain) test-repro

.PHONY: test
test: test-repro

.PHONY: machine-shell
machine-shell:
	@scripts/machine

.PHONY: shell
shell:
	@$(contain) shell

.PHONY: diff
diff:
	@$(contain) bash -c "cd base; repo diff -u"

.PHONY: clean
clean: image
	@$(contain) clean

mrproper:
	docker-machine rm -f aosp-build
	rm -rf build

.PHONY: install
install: tools
	@scripts/flash
