IMAGE ?= neosun100/kimi-linear-vllm:latest
CONTAINER ?= kimi48b-awq
HOST_PORT ?= 8002
CONTAINER_PORT ?= 8000
HF_HOME ?= $(HOME)/.cache/huggingface
DOWNLOAD_DIR ?= $(HOME)/vllm_downloads

.PHONY: build run stop logs push ghcr-push

build:
	docker build -t $(IMAGE) .

run:
	mkdir -p $(HF_HOME) $(DOWNLOAD_DIR)
	docker run --gpus all -d --name $(CONTAINER) --restart unless-stopped \
	  --ipc=host -p $(HOST_PORT):$(CONTAINER_PORT) \
	  -v $(HF_HOME):/root/.cache/huggingface \
	  -v $(DOWNLOAD_DIR):/data/vllm_downloads \
	  $(IMAGE)

stop:
	- docker rm -f $(CONTAINER)

logs:
	docker logs -f $(CONTAINER)

push:
	# Docker Hub push (requires `docker login`)
	docker push $(IMAGE)

# Optional: push to GitHub Container Registry (requires `gh auth login` and "write:packages")
GHCR_IMAGE ?= ghcr.io/neosun100/kimi-linear-vllm:latest

ghcr-push:
	docker tag $(IMAGE) $(GHCR_IMAGE)
	docker push $(GHCR_IMAGE)
