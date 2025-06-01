# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the Cloudflare Tunnel Template.

## Overview

This is a reusable template for deploying Docker services with Cloudflare tunnels. It provides secure external access to containerized services through Cloudflare's network.

## Template Structure

```
cloudflare-tunnel-template/
├── terraform/           # Infrastructure as Code
├── docker/             # Docker Compose templates
├── scripts/            # Deployment automation
├── .env.example        # Environment template
└── CLAUDE.md          # This file
```

## How to Deploy a New Service

When asked to create a new service with Cloudflare tunnel access, follow these steps:

### 1. Copy the Template

```bash
# Copy template to new service directory
cp -r /home/andrew/stacks/cloudflare-tunnel-template /home/andrew/stacks/docker/SERVICE_NAME

# Navigate to the new directory
cd /home/andrew/stacks/docker/SERVICE_NAME
```

### 2. Create Environment Configuration

Create `.env` file with these required variables:

```bash
# Cloudflare Credentials (from existing setup)
CLOUDFLARE_API_TOKEN=your-api-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_ZONE_ID=your-zone-id

# Service Configuration
TUNNEL_NAME=service-name          # Unique identifier for this tunnel
DOMAIN=example.com               # Your domain
SUBDOMAIN=service                # Subdomain (optional, leave empty for root)
SERVICE_PORT=8080                # Port your service runs on

# Optional Authentication
AUTH_METHOD=none                 # Options: none, email, service_token
AUTH_EMAILS=                     # Comma-separated emails if using email auth
```

### 3. Customize Docker Compose

Replace the template `docker-compose.yml` with service-specific configuration:

```yaml
version: '3.8'

services:
  # Replace with actual service configuration
  app:
    image: actual-service-image:tag
    container_name: ${TUNNEL_NAME}-app
    restart: unless-stopped
    ports:
      - "127.0.0.1:${SERVICE_PORT}:${SERVICE_PORT}"
    environment:
      # Service-specific environment variables
    volumes:
      # Service-specific volumes
    networks:
      - tunnel_network

  # Keep cloudflared as-is
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: ${TUNNEL_NAME}-cloudflared
    restart: unless-stopped
    command: tunnel run
    networks:
      - tunnel_network
    volumes:
      - ./cloudflared/config.yml:/home/nonroot/.cloudflared/config.yml:ro
      - ./cloudflared/credentials.json:/home/nonroot/.cloudflared/credentials.json:ro
    depends_on:
      - app

networks:
  tunnel_network:
    driver: bridge

volumes:
  # Define service-specific volumes
```

### 4. Create Makefile

Create a `Makefile` following the established pattern:

```makefile
.PHONY: create stop destroy logs

create:
	@echo "Deploying SERVICE_NAME with Cloudflare tunnel..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh

stop:
	@echo "Stopping SERVICE_NAME..."
	@docker compose down

destroy:
	@echo "Destroying SERVICE_NAME and tunnel..."
	@chmod +x scripts/destroy.sh
	@./scripts/destroy.sh

logs:
	@docker compose logs -f
```

### 5. Deploy the Service

```bash
make create
```

## Important Implementation Notes

### For Services Requiring Network Mode

Some services (like ThetaData) need `network_mode: "service:app"`. Use the alternative template:

```yaml
# Use docker/docker-compose.network-mode.yml as base
cloudflared:
  network_mode: "service:app"  # Shares network namespace with app
```

### Authentication Methods

1. **No Auth** (`AUTH_METHOD=none`): Public access
2. **Email Auth** (`AUTH_METHOD=email`): Requires Cloudflare login
3. **Service Token** (`AUTH_METHOD=service_token`): For API access

### Terraform State

- State is stored locally in `terraform/terraform.tfstate`
- Each service maintains its own state
- Never commit state files to git

### Common Customizations

1. **Multiple Services**: Add more ingress rules in `terraform/main.tf`
2. **Custom Health Checks**: Modify the cloudflared healthcheck in docker-compose
3. **Advanced Routing**: Edit the tunnel config in `terraform/main.tf`

## Debugging

Check tunnel status:
```bash
docker logs SERVICE_NAME-cloudflared
docker exec SERVICE_NAME-cloudflared cloudflared tunnel info
```

## Example Deployments

### Simple Web App
```env
TUNNEL_NAME=my-web-app
SUBDOMAIN=app
SERVICE_PORT=3000
AUTH_METHOD=email
AUTH_EMAILS=admin@example.com
```

### API Service
```env
TUNNEL_NAME=api-service
SUBDOMAIN=api
SERVICE_PORT=8080
AUTH_METHOD=service_token
```

### Database UI
```env
TUNNEL_NAME=db-admin
SUBDOMAIN=db
SERVICE_PORT=8080
AUTH_METHOD=email
AUTH_EMAILS=dba@example.com,admin@example.com
```

## Best Practices

1. Always use unique TUNNEL_NAME values
2. Set appropriate AUTH_METHOD based on service type
3. Use subdomain instead of path-based routing
4. Keep credentials in .env, never in docker-compose.yml
5. Run `make destroy` before deleting a service directory