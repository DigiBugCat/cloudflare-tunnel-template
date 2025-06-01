# Cloudflare Tunnel Template

A clean, reusable template for deploying services with Cloudflare tunnels. This template provides a secure, standardized way to expose your Docker services to the internet through Cloudflare's network.

## Features

- 🔒 Secure credential management via environment variables
- 🚀 One-command deployment with automated setup
- 🔧 Flexible configuration for any domain
- 📦 Reusable Terraform module
- 🐳 Docker Compose integration
- 🔄 Support for multiple authentication methods
- 📝 Clear documentation and examples

## Quick Start

1. **Copy the template to your service directory:**
   ```bash
   cp -r /home/andrew/stacks/cloudflare-tunnel-template /path/to/your/service
   cd /path/to/your/service
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your Cloudflare credentials and service details
   ```

3. **Deploy your service:**
   ```bash
   ./scripts/deploy.sh
   ```

That's it! Your service is now accessible via Cloudflare tunnel.

## Directory Structure

```
cloudflare-tunnel-template/
├── terraform/           # Terraform configuration
│   ├── main.tf         # Main Terraform config
│   ├── variables.tf    # Variable definitions
│   └── outputs.tf      # Output values
├── docker/             # Docker configurations
│   ├── docker-compose.template.yml
│   └── Dockerfile.example
├── scripts/            # Automation scripts
│   ├── deploy.sh      # Full deployment script
│   ├── setup.sh       # Initial setup script
│   └── destroy.sh     # Cleanup script
├── examples/           # Example configurations
│   ├── simple-web-app/
│   └── multi-service/
├── .env.example        # Environment template
└── README.md           # This file
```

## Configuration

### Required Environment Variables

Create a `.env` file with these variables:

```bash
# Cloudflare Credentials
CLOUDFLARE_API_TOKEN=your-api-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_ZONE_ID=your-zone-id

# Tunnel Configuration
TUNNEL_NAME=my-service
DOMAIN=example.com
SUBDOMAIN=my-service
SERVICE_PORT=8080

# Optional: Authentication
AUTH_METHOD=service_token  # or "email" or "none"
AUTH_EMAILS=user@example.com,admin@example.com
```

### Advanced Options

See `terraform/variables.tf` for all available options.

## Usage Examples

### Simple Web Application

```bash
cd examples/simple-web-app
./deploy.sh
```

### Multiple Services

```bash
cd examples/multi-service
./deploy.sh
```

## Security Best Practices

1. **Never commit `.env` files** - Use `.env.example` as a template
2. **Use service tokens** instead of email auth when possible
3. **Rotate credentials regularly**
4. **Limit tunnel access** to specific IP ranges if needed

## Troubleshooting

### Common Issues

1. **Tunnel won't start**: Check credentials in `.env`
2. **Can't access service**: Verify SERVICE_PORT matches your container
3. **DNS not resolving**: Wait 1-2 minutes for propagation

### Debug Commands

```bash
# Check tunnel status
docker logs cloudflared

# Verify Terraform state
cd terraform && tofu state list

# Test local service
curl http://localhost:${SERVICE_PORT}
```

## Contributing

Feel free to submit improvements to this template!

## License

MIT License - Use freely in your projects.