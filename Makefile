device = ${DEVICE}
userid = $(shell id -u)
groupid = $(shell id -g)
image = "hashbang/aosp-build:latest"

.DEFAULT_GOAL := default

contain := \
	mkdir -p keys build/base && \
	mkdir -p keys build/release && \
	mkdir -p keys build/external && \
	mkdir -p keys build/.kube && \
	docker run -it --rm -h "android" \
		-v $(PWD)/build/.kube:/home/build/.kube \
		-v $(PWD)/build/base:/home/build/base \
		-v $(PWD)/build/release:/home/build/release \
		-v $(PWD)/build/external:/home/build/external \
		-v $(PWD)/keys:/home/build/keys \
		-v $(PWD)/scripts:/home/build/scripts \
		-v $(PWD)/config.yml:/home/build/config.yml \
		-v $(PWD)/manifests:/home/build/manifests \
		-v $(PWD)/patches:/home/build/patches \
		-v $(PWD)/terraform:/home/build/terraform \
		--env-file=$(PWD)/.terraform.env \
		-u $(userid):$(groupid) \
		-e DEVICE=$(device) \
		$(image)

default: build

image:
	@docker build \
		--build-arg UID=$(userid) \
		--build-arg GID=$(groupid) \
		-t $(image) .

manifest: image
	$(contain) manifest

config: manifest
	$(contain) config

fetch:
	mkdir -p build
	@$(contain) fetch

tools: fetch image
	@$(contain) tools

keys: tools
	@$(contain) keys

build: image tools
	@$(contain) build

kernel: tools
	@$(contain) build-kernel

vendor: tools
	@$(contain) build-vendor

chromium: tools
	@$(contain) build-chromium

release: tools
	mkdir -p build/release
	@$(contain) release

test-repro:
	@$(contain) test-repro

test: test-repro

infra:
	@$(contain) bash -c ' \
		helm init --client-only;  \
		cd /home/build/terraform ; \
		terraform init \
			-backend-config=bucket="$$TF_BUCKET"  \
			-backend-config=key="$$TF_KEY" ; \
		terraform apply \
	'

shell:
	@$(contain) shell

diff:
	@$(contain) bash -c "cd base; repo diff -u"

clean: image
	@$(contain) clean

mrproper: clean
	@docker image rm -f $(image)
	rm -rf build

install: tools
	@scripts/flash

.PHONY: image build shell diff install update flash clean tools default
