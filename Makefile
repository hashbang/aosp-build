CPUS := "2"
device = ${DEVICE}
userid = $(shell id -u)
groupid = $(shell id -g)
image = "hashbang/aosp-build:latest"
contain := \
	mkdir -p keys build/base && \
	mkdir -p keys build/release && \
	mkdir -p keys build/external && \
	docker run -it --rm -h "android" \
		-v $(PWD)/build/base:/home/build/base \
		-v $(PWD)/build/release:/home/build/release \
		-v $(PWD)/build/external:/home/build/external \
		-v $(PWD)/keys:/home/build/keys \
		-v $(PWD)/scripts:/home/build/scripts \
		-v $(PWD)/config.yml:/home/build/config.yml \
		-v $(PWD)/manifests:/home/build/manifests \
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
	@docker build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t $(image) .

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

.PHONY: shell
shell:
	@$(contain) shell

.PHONY: diff
diff:
	@$(contain) bash -c "cd base; repo diff -u"

.PHONY: clean
clean: image
	@$(contain) clean

.PHONY: mrproper
mrproper: clean
	@docker image rm -f $(image)
	rm -rf build

.PHONY: install
install: tools
	@scripts/flash
