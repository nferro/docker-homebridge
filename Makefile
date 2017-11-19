IMAGE_NAME=rcarmo/homebridge
HOSTNAME?=homebridge
export ARCH?=$(shell arch)
ifeq ($(ARCH),armhf)
export BASE=armv7/armhf-ubuntu:16.04
else
export BASE=ubuntu:16.04
endif
export DATA_FOLDER=$(HOME)/.homebridge
export VCS_REF=`git rev-parse --short HEAD`
export VCS_URL=https://github.com/rcarmo/docker-homebridge-armhf
export BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
build: Dockerfile
	docker build -t $(IMAGE_NAME):$(ARCH)

push:
	docker push $(IMAGE_NAME)

network:
	-docker network create -d macvlan \
	--subnet=192.168.1.0/24 \
        --gateway=192.168.1.254 \
	--ip-range=192.168.1.128/25 \
	-o parent=eth0 \
	lan

shell:
	docker run --net=lan -h $(HOSTNAME) -it $(IMAGE_NAME):$(ARCH) /bin/sh

test: 
	docker run -v $(DATA_FOLDER):/home/user/.homebridge \
		--net=host -h $(HOSTNAME) $(IMAGE_NAME):$(ARCH)

daemon: network
	-mkdir -p $(DATA_FOLDER)
	docker run -v $(DATA_FOLDER):/home/user/.homebridge \
		--net=lan -h $(HOSTNAME) -d --restart unless-stopped $(IMAGE_NAME):$(ARCH)

clean:
	-docker rm -v $$(docker ps -a -q -f status=exited)
	-docker rmi $$(docker images -q -f dangling=true)
	-docker rmi $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep '$(IMAGE_NAME)')
