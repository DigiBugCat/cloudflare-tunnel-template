#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Cloudflare Tunnel Initial Setup${NC}"
echo "=================================="

# Create .env from example if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
    echo -e "${YELLOW}Created .env file from template${NC}"
    echo "Please edit .env with your Cloudflare credentials and configuration"
fi

# Make scripts executable
chmod +x scripts/*.sh

# Create necessary directories
mkdir -p cloudflared
mkdir -p terraform/.terraform

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo "Next steps:"
echo "1. Edit .env with your configuration"
echo "2. Run ./scripts/deploy.sh to deploy your service"