#!/bin/bash

# Script to generate Kubernetes secrets.yaml from .env file

ENV_FILE="${1:-../.env}"
OUTPUT_FILE="${2:-secrets.yaml}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE" >&2
    exit 1
fi

# Start writing the YAML file
cat > "$OUTPUT_FILE" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: auravault-secrets
  namespace: auravault
type: Opaque
stringData:
EOF

# Read .env file and process each line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Remove leading/trailing whitespace
    line=$(echo "$line" | xargs)
    
    # Skip if empty after trimming
    [[ -z "$line" ]] && continue
    
    # Extract key and value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Remove quotes from value if present
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        
        # Special handling for POSTGRES_HOST - use "postgres" for k8s service name
        if [ "$key" = "POSTGRES_HOST" ]; then
            value="postgres"
        fi
        
        # Skip DEBUG and ALLOWED_HOSTS as they're not needed in secrets
        if [ "$key" = "DEBUG" ] || [ "$key" = "ALLOWED_HOSTS" ]; then
            continue
        fi
        
        # Write to YAML file with proper indentation
        echo "  $key: \"$value\"" >> "$OUTPUT_FILE"
    fi
done < "$ENV_FILE"

echo "Generated $OUTPUT_FILE from $ENV_FILE"
