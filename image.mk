.PHONY: help image init-builder cache clean-builder clean-cache

help:
	@echo "image ........................... build the image"
	@echo "init-builder .................... intialize building context"
	@echo "  clean-builder ................. clean building context"
	@echo "  clean-cache ................... clean cache"

DOCKER_CACHE_NEW=$(DOCKER_CACHE)-new

init-builder: $(DOCKER_CACHE)
	DOCKER_BUILDER=$(DOCKER_BUILDER) \
	DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
	$(LIBDIR)/init-builder

clean-builder:
	docker buildx rm $(DOCKER_BUILDER) || true

$(DOCKER_CACHE):
	mkdir -p $(DOCKER_CACHE)

$(DOCKER_CACHE_NEW):
	mkdir -p $(DOCKER_CACHE_NEW)

clean-cache:
	rm -rf $(DOCKER_CACHE) $(DOCKER_CACHE_NEW)

$(DOCKER_REPO_OWNER)/%: STAMP?=$(shell git rev-parse --verify HEAD || echo latest)
$(DOCKER_REPO_OWNER)/%: IMAGE_TAG?=$(STAMP)
$(DOCKER_REPO_OWNER)/%: $(DOCKER_CACHE) $(DOCKER_CACHE_NEW)
	$(MAKE) init-builder && \
	docker buildx build --builder $(DOCKER_BUILDER) \
		--provenance=false \
		--cache-from type=local,src=$(DOCKER_CACHE) \
		--cache-to type=local,dest=$(DOCKER_CACHE_NEW),mode=max \
		--output type=image,push=true \
		--platform linux/amd64,linux/arm64 \
		--tag $(DOCKER_REGISTRY)/$@:$(IMAGE_TAG) \
		--build-arg DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
		--build-arg STAMP=$(STAMP) \
		-f $(CURDIR)/Dockerfile \
		$(CURDIR) && \
		rm -rf $(DOCKER_CACHE) && \
		mv $(DOCKER_CACHE_NEW) $(DOCKER_CACHE)
