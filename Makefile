# ==============================================================================
# Deskbox Desktop Environment - Makefile
# ==============================================================================
# Manages desktop environment lifecycle via Docker/Docker Compose
#
# Usage: make [target] CTX=<context>
# Example: make build CTX=production
#          make start CTX=default
# ==============================================================================

# Load environment variables from .env file if it exists
-include .env
export

# Docker context (allows deployment to remote hosts configured in Docker)
# Use: docker context create <name> --docker "host=ssh://user@host"
CTX ?= default

# Base Docker command using the specified context
DOCKER_CMD = docker --context $(CTX)

# Docker Compose command derived from context
COMPOSE = $(DOCKER_CMD) compose

# Docker Hub username (from .env or default)
DOCKER_USER ?= carlosrabelo

# Image name (from .env or default)
IMAGE_NAME ?= deskbox

# Full image name on Docker Hub
REPO_IMAGE = $(DOCKER_USER)/$(IMAGE_NAME)

# Image version (from .env or default)
VERSION ?= 0.0.1

# User configuration (fixed)
USER_NAME = deskbox
USER_UID ?= 1000
USER_GID ?= 1000

# Declares targets that don't create files
.PHONY: all help build start stop restart ps logs exec config push clean clean-all backup sessions view-logs

all: help

help:
	@echo "Usage: make [target] CTX=<context> [DOCKER_USER=user] [IMAGE_NAME=name] [VERSION=x.y.z] [USER_UID=uid] [USER_GID=gid]"
	@echo ""
	@echo "Configuration: Copy .env.example to .env and customize (recommended)"
	@echo ""
	@echo "Current settings:"
	@echo "  Context: $(CTX)"
	@echo "  Docker User: $(DOCKER_USER)"
	@echo "  Image Name: $(IMAGE_NAME)"
	@echo "  Version: $(VERSION)"
	@echo "  Full Image: $(REPO_IMAGE):$(VERSION)"

	@echo "  User UID: $(USER_UID)"
	@echo "  User GID: $(USER_GID)"
	@echo ""
	@echo "Available targets:"
	@echo "  init               Initialize directories on remote host"
	@echo "  build              Build Docker image"
	@echo "  push               Build and push image to Docker Hub"
	@echo "                     (also tags as latest if VERSION != latest)"
	@echo "  start              Start containers"
	@echo "  stop               Stop containers"
	@echo "  restart            Restart containers"
	@echo "  ps                 List containers"
	@echo "  logs               Display logs in real-time"
	@echo "  view-logs          View Deskbox startup and XRDP logs"
	@echo "  exec SVC=deskbox   Open shell in container"
	@echo "  sessions           Show active user sessions"
	@echo "  backup             Create backup of /mnt/deskbox/home"
	@echo "  config             Display processed docker-compose.yml"
	@echo "  clean              Remove local Docker images (current version)"
	@echo "  clean-all          Stop containers and remove all project images"
	@echo ""
	@echo "Examples:"
	@echo "  cp .env.example .env            Create config file"
	@echo "  make push VERSION=1.0.0         Push version 1.0.0 and latest"
	@echo "  make push                       Push default version and latest"
	@echo "  make build DOCKER_USER=myuser   Override Docker Hub user"
	@echo "  make sessions CTX=hostname      View active sessions"
	@echo "  make backup CTX=hostname        Create backup of user data"

# Builds Docker image using multi-stage Dockerfile
# Leverages layer cache for fast incremental builds
# Usage: make build VERSION=1.0.0 (or defaults to '0.0.1')
build:
	@echo "Building Docker image $(REPO_IMAGE):$(VERSION) in context $(CTX)..."
	@DOCKER_USER=$(DOCKER_USER) IMAGE_NAME=$(IMAGE_NAME) VERSION=$(VERSION) $(COMPOSE) build
	@if [ "$(VERSION)" != "latest" ]; then \
		$(DOCKER_CMD) tag $(REPO_IMAGE):$(VERSION) $(REPO_IMAGE):latest; \
		echo "Tagged as $(REPO_IMAGE):$(VERSION) and $(REPO_IMAGE):latest"; \
	fi

# Initializes directory structure on remote host via Docker Context
# Creates /mnt/deskbox/home and basic user structure
# Uses a temporary busybox container to create directories
init:
	@echo "Initializing directories on host context $(CTX)..."
	@$(DOCKER_CMD) run --rm \
		-v /mnt/deskbox:/mnt/deskbox \
		busybox sh -c "mkdir -p /mnt/deskbox/home /mnt/deskbox/logs && chown -R $(USER_UID):$(USER_GID) /mnt/deskbox && echo 'Directories created and permissions set'"

# Starts containers in daemon mode (background)
# --remove-orphans: removes orphan containers from previous runs
start:
	@DOCKER_USER=$(DOCKER_USER) IMAGE_NAME=$(IMAGE_NAME) VERSION=$(VERSION) $(COMPOSE) up -d --remove-orphans

# Stops and removes containers, networks, and anonymous volumes
stop:
	@$(COMPOSE) down

# Restarts containers (stop + start)
restart: stop start

# Lists container status
ps:
	@$(COMPOSE) ps

# Displays real-time logs (last 100 lines)
# Use Ctrl+C to exit
logs:
	@$(COMPOSE) logs -f --tail=100

# Opens bash shell in a specific container
# Usage: make exec SVC=deskbox
exec:
	@$(COMPOSE) exec $(SVC) /bin/bash

# Validates and displays processed docker-compose.yml configuration
config:
	@DOCKER_USER=$(DOCKER_USER) IMAGE_NAME=$(IMAGE_NAME) VERSION=$(VERSION) $(COMPOSE) config

# Builds and pushes image to Docker Hub
# Requires: docker login to your Docker Hub account
# Usage: make push VERSION=1.0.0 (or defaults to '0.0.1')
push: build
	@echo "Pushing $(REPO_IMAGE):$(VERSION)..."
	@$(DOCKER_CMD) push $(REPO_IMAGE):$(VERSION)
	@if [ "$(VERSION)" != "latest" ]; then \
		$(DOCKER_CMD) push $(REPO_IMAGE):latest; \
	fi
	@echo "Pushed successfully!"

# Removes local Docker images
# Removes both the version tag and latest tag
clean:
	@echo "Removing local images..."
	@$(DOCKER_CMD) rmi $(REPO_IMAGE):$(VERSION) 2>/dev/null || true
	@if [ "$(VERSION)" != "latest" ]; then \
		$(DOCKER_CMD) rmi $(REPO_IMAGE):latest 2>/dev/null || true; \
	fi
	@echo "Local images removed!"

# Deep clean: stops containers and removes all project images
# Removes all tags of the project image
clean-all: stop
	@echo "Removing all project images..."
	@$(DOCKER_CMD) images $(REPO_IMAGE) -q | xargs -r $(DOCKER_CMD) rmi -f 2>/dev/null || true
	@echo "All project images removed!"

# Creates backup of /mnt/deskbox/home directory on remote host
# Backup file is saved to /tmp with timestamp
backup:
	@echo "Creating backup of /mnt/deskbox/home on $(CTX)..."
	@BACKUP_FILE="deskbox-backup-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	ssh root@$(CTX) "tar -czf /tmp/$$BACKUP_FILE /mnt/deskbox/home 2>/dev/null && echo 'Backup created: /tmp/'$$BACKUP_FILE && ls -lh /tmp/$$BACKUP_FILE"
	@echo "Backup completed successfully!"

# Shows active user sessions in the container
# Displays who is logged in and session information
sessions:
	@echo "Active sessions in Deskbox container:"
	@echo "-----------------------------------"
	@$(COMPOSE) exec deskbox who || true
	@echo ""
	@echo "Detailed session information:"
	@echo "-----------------------------------"
	@$(COMPOSE) exec deskbox loginctl list-sessions 2>/dev/null || echo "No sessions found or loginctl not available"

# Views Deskbox startup and XRDP logs from the container
# Shows last 50 lines of each log file
view-logs:
	@echo "==================================================================="
	@echo "Deskbox Startup Logs"
	@echo "==================================================================="
	@$(COMPOSE) exec deskbox tail -n 50 /var/log/deskbox/startup.log 2>/dev/null || echo "No startup logs found"
	@echo ""
	@echo "==================================================================="
	@echo "XRDP Server Logs"
	@echo "==================================================================="
	@$(COMPOSE) exec deskbox tail -n 50 /var/log/deskbox/xrdp.log 2>/dev/null || echo "No XRDP logs found"
