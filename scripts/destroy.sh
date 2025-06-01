#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}🗑️  Cloudflare Tunnel Destroy Script${NC}"
echo "======================================"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

# Confirm destruction
echo -e "${YELLOW}⚠️  WARNING: This will destroy:${NC}"
echo "  - Docker containers for $TUNNEL_NAME"
echo "  - Cloudflare tunnel and DNS records"
echo "  - All terraform resources"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Destruction cancelled."
    exit 0
fi

# Stop Docker containers
echo -e "\n${YELLOW}🐳 Stopping Docker containers...${NC}"
if docker compose version >/dev/null 2>&1; then
    docker compose down || true
else
    docker-compose down || true
fi

# Destroy Terraform resources
echo -e "\n${YELLOW}🔧 Destroying Cloudflare infrastructure...${NC}"
cd "$PROJECT_ROOT/terraform"

if command -v tofu >/dev/null 2>&1; then
    TF_CMD="tofu"
else
    TF_CMD="terraform"
fi

$TF_CMD destroy \
    -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" \
    -var="cloudflare_account_id=$CLOUDFLARE_ACCOUNT_ID" \
    -var="cloudflare_zone_id=$CLOUDFLARE_ZONE_ID" \
    -var="tunnel_name=$TUNNEL_NAME" \
    -var="domain=$DOMAIN" \
    -var="subdomain=${SUBDOMAIN:-}" \
    -var="service_port=$SERVICE_PORT" \
    -var="auth_method=${AUTH_METHOD:-none}" \
    -var="auth_emails=${AUTH_EMAILS:-[]}" \
    -auto-approve

cd "$PROJECT_ROOT"

# Clean up files
echo -e "\n${YELLOW}🧹 Cleaning up files...${NC}"
rm -rf "$PROJECT_ROOT/cloudflared"
rm -rf "$PROJECT_ROOT/terraform/.terraform"
rm -f "$PROJECT_ROOT/terraform/.terraform.lock.hcl"
rm -f "$PROJECT_ROOT/terraform/terraform.tfstate*"

echo -e "\n${GREEN}✅ Destruction complete!${NC}"