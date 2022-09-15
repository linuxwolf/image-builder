.PHONY: help image init-builder cache clean-builder clean-cache

help:
	@echo "image ........................... build the image"
	@echo "init-builder .................... intialize building context"
	@echo "  clean-builder ................. clean building context"
	@echo "  clean-cache ................... clean cache"
	@echo ""
	@echo "stamp: $(STAMP)"
	
init-builder: $(DOCKER_CACHE)
	DOCKER_BUILDER=$(DOCKER_BUILDER) \
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
	$(LIBDIR)/init-builder

clean-builder:
	docker buildx rm $(DOCKER_BUILDER) || true

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

clean-cache:
	rm -rf $(DOCKER_CACHE)

$(DOCKER_REPO_OWNER)/%: STAMP?=$(shell git rev-parse --verify HEAD || echo latest)
$(DOCKER_REPO_OWNER)/%: IMAGE_TAG?=$(STAMP)
$(DOCKER_REPO_OWNER)/%: .cache/docker
	$(MAKE) init-builder && \
	docker buildx build --builder $(DOCKER_BUILDER) \
		--cache-from type=local,src=.cache/docker \
		--cache-to type=local,dest=.cache/docker,mode=max \
		--output type=image,push=true \
		--platform linux/amd64,linux/arm64 \
		--tag $(DOCKER_REGISTRY)/$@:$(IMAGE_TAG) \
		--build-arg DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
		--build-arg STAMP=$(STAMP) \
		-f $(CURDIR)/Dockerfile \
		$(CURDIR)
