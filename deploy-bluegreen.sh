#!/bin/bash
set -e

CONFIG="/etc/nginx/nginx.conf"

# Detect active backend
ACTIVE_BACKEND=$(grep -o "backend-[a-z]*:8000" $CONFIG | head -1 || true)

if [ "$ACTIVE_BACKEND" = "backend-blue:8000" ]; then
    NEW_CONTAINER="backend-green"
    OLD_CONTAINER="backend-blue"
    NEW_BACKEND="backend-green:8000"
    NEW_HOST_PORT=8002
else
    NEW_CONTAINER="backend-blue"
    OLD_CONTAINER="backend-green"
    NEW_BACKEND="backend-blue:8000"
    NEW_HOST_PORT=8001
fi

echo "Current active: ${ACTIVE_BACKEND:-none}"
echo "Deploying new version to: $NEW_CONTAINER"

# Pull latest image
sudo docker pull vivekbackend.duckdns.org:5000/backend:1

# Remove old standby container if exists
sudo docker rm -f $NEW_CONTAINER || true

# Run new container
sudo docker run -d \
    --name $NEW_CONTAINER \
    -p $NEW_HOST_PORT:8000 \
    --network fullstack-project_default \
    -e DATABASE_URL=postgresql://admin:password@db:5432/appdb \
    vivekbackend.duckdns.org:5000/backend:1

# Wait for startup
echo "Waiting 10 seconds..."
sleep 10

# Health check
HEALTH=$(curl -s http://localhost:$NEW_HOST_PORT/health || true)

if [[ "$HEALTH" == *"healthy"* ]]; then
    echo "Health check PASSED. Switching traffic..."

    # Backup current Nginx config
    sudo cp $CONFIG $CONFIG.bak

    # If upstream exists, replace old backend
    if grep -q "upstream backend {" $CONFIG; then
        sudo sed -i "s|server $ACTIVE_BACKEND;|server $NEW_BACKEND;|" $CONFIG
    else
        # Add upstream block if missing
        sudo sed -i "/http {/a \    upstream backend {\n        server $NEW_BACKEND;\n    }" $CONFIG
        sudo sed -i "/server {/a \        location /api/ {\n            proxy_pass http://backend;\n        }" $CONFIG
    fi

    # Reload Nginx
    sudo nginx -s reload

    # Stop old container
    sudo docker rm -f $OLD_CONTAINER || true

    echo "Deployment SUCCESSFUL"
else
    echo "Health check FAILED. Rolling back..."
    sudo docker rm -f $NEW_CONTAINER || true
    echo "Rollback complete. Traffic unchanged."
    exit 1
fi
