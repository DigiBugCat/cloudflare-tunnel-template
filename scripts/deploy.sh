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

echo -e "${GREEN}🚀 Cloudflare Tunnel Deployment Script${NC}"
echo "======================================"

# Check for required tools
check_requirements() {
    local missing_tools=()
    
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    command -v docker-compose >/dev/null 2>&1 || command -v docker compose >/dev/null 2>&1 || missing_tools+=("docker-compose")
    command -v tofu >/dev/null 2>&1 || command -v terraform >/dev/null 2>&1 || missing_tools+=("tofu/terraform")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        exit 1
    fi
}

# Load environment variables
load_env() {
    if [ -f "$PROJECT_ROOT/.env" ]; then
        export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
    else
        echo -e "${RED}Error: .env file not found!${NC}"
        echo "Please copy .env.example to .env and fill in your values."
        exit 1
    fi
}

# Validate environment variables
validate_env() {
    local required_vars=(
        "CLOUDFLARE_API_TOKEN"
        "CLOUDFLARE_ACCOUNT_ID"
        "CLOUDFLARE_ZONE_ID"
        "TUNNEL_NAME"
        "DOMAIN"
        "SERVICE_PORT"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required environment variables:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        exit 1
    fi
}

# Create necessary directories
setup_directories() {
    echo -e "${YELLOW}📁 Setting up directories...${NC}"
    mkdir -p "$PROJECT_ROOT/cloudflared"
    mkdir -p "$PROJECT_ROOT/terraform/.terraform"
}

# Deploy infrastructure with Terraform
deploy_terraform() {
    echo -e "${YELLOW}🔧 Deploying Cloudflare infrastructure...${NC}"
    
    cd "$PROJECT_ROOT/terraform"
    
    # Use tofu if available, otherwise terraform
    if command -v tofu >/dev/null 2>&1; then
        TF_CMD="tofu"
    else
        TF_CMD="terraform"
    fi
    
    # Initialize Terraform
    $TF_CMD init -upgrade
    
    # Plan and apply
    $TF_CMD plan \
        -var="cloudflare_api_token=$CLOUDFLARE_API_TOKEN" \
        -var="cloudflare_account_id=$CLOUDFLARE_ACCOUNT_ID" \
        -var="cloudflare_zone_id=$CLOUDFLARE_ZONE_ID" \
        -var="tunnel_name=$TUNNEL_NAME" \
        -var="domain=$DOMAIN" \
        -var="subdomain=${SUBDOMAIN:-}" \
        -var="service_port=$SERVICE_PORT" \
        -var="auth_method=${AUTH_METHOD:-none}" \
        -var="auth_emails=${AUTH_EMAILS:-[]}" \
        -out=tfplan
    
    $TF_CMD apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    cd "$PROJECT_ROOT"
}

# Set correct permissions on credential files
fix_permissions() {
    echo -e "${YELLOW}🔒 Setting file permissions...${NC}"
    
    # Ensure cloudflared can read the files
    if [ -f "$PROJECT_ROOT/cloudflared/credentials.json" ]; then
        chmod 600 "$PROJECT_ROOT/cloudflared/credentials.json"
    fi
    
    if [ -f "$PROJECT_ROOT/cloudflared/config.yml" ]; then
        chmod 644 "$PROJECT_ROOT/cloudflared/config.yml"
    fi
}

# Deploy Docker containers
deploy_docker() {
    echo -e "${YELLOW}🐳 Starting Docker containers...${NC}"
    
    # Check if docker-compose.yml exists, if not copy template
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        echo "No docker-compose.yml found, using template..."
        cp "$PROJECT_ROOT/docker/docker-compose.template.yml" "$PROJECT_ROOT/docker-compose.yml"
        echo -e "${YELLOW}⚠️  Please edit docker-compose.yml for your specific application${NC}"
    fi
    
    # Use docker compose v2 if available
    if docker compose version >/dev/null 2>&1; then
        docker compose up -d
    else
        docker-compose up -d
    fi
}

# Get tunnel information
show_info() {
    echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
    echo "======================================"
    
    cd "$PROJECT_ROOT/terraform"
    
    if command -v tofu >/dev/null 2>&1; then
        TUNNEL_URL=$($tofu output -raw tunnel_url 2>/dev/null || echo "")
    else
        TUNNEL_URL=$(terraform output -raw tunnel_url 2>/dev/null || echo "")
    fi
    
    if [ -n "$TUNNEL_URL" ]; then
        echo -e "🌐 Your service is available at: ${GREEN}$TUNNEL_URL${NC}"
    fi
    
    cd "$PROJECT_ROOT"
    
    echo -e "\n📊 Container Status:"
    docker ps --filter "name=${TUNNEL_NAME}"
    
    echo -e "\n📝 Next Steps:"
    echo "  - Check logs: docker logs ${TUNNEL_NAME}-cloudflared"
    echo "  - Monitor tunnel: docker exec ${TUNNEL_NAME}-cloudflared cloudflared tunnel info"
    echo "  - Stop services: ./scripts/destroy.sh"
}

# Main execution
main() {
    check_requirements
    load_env
    validate_env
    setup_directories
    deploy_terraform
    fix_permissions
    deploy_docker
    show_info
}

# Run main function
main "$@"