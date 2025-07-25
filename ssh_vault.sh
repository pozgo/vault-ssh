#!/bin/bash

# SSH Vault - Shell functions for SSH with HashiCorp Vault passwords

# SSH Vault Configuration Management

# Default configuration file location
SSH_VAULT_CONFIG_FILE="${SSH_VAULT_CONFIG_FILE:-$HOME/.ssh_vault_config}"

# Load configuration from file
vault_config_load() {
    if [[ -f "$SSH_VAULT_CONFIG_FILE" ]]; then
        source "$SSH_VAULT_CONFIG_FILE"
    fi
}

# Save configuration to file
vault_config_save() {
    cat > "$SSH_VAULT_CONFIG_FILE" << EOF
# SSH Vault Configuration
export VAULT_ADDR="$VAULT_ADDR"
export VAULT_TOKEN="$VAULT_TOKEN"
export VAULT_MOUNT_PATH="${VAULT_MOUNT_PATH:-secret}"
export VAULT_SECRET_PATH="${VAULT_SECRET_PATH:-ssh}"
EOF
    chmod 600 "$SSH_VAULT_CONFIG_FILE"
}

# Set individual configuration parameter
vault_config_set() {
    local key="$1"
    local value="$2"
    
    if [[ -z "$key" || -z "$value" ]]; then
        echo "📖 Usage: vault_config_set KEY VALUE"
        echo "   Valid keys: VAULT_ADDR, VAULT_TOKEN, VAULT_MOUNT_PATH, VAULT_SECRET_PATH"
        return 1
    fi
    
    # Load existing config
    vault_config_load
    
    # Set the new value
    case "$key" in
        VAULT_ADDR)
            export VAULT_ADDR="$value"
            echo "🌐 Updated vault address: $value"
            ;;
        VAULT_TOKEN)
            export VAULT_TOKEN="$value"
            echo "🔑 Updated vault token: [HIDDEN]"
            ;;
        VAULT_MOUNT_PATH)
            export VAULT_MOUNT_PATH="$value"
            echo "📁 Updated mount path: $value"
            ;;
        VAULT_SECRET_PATH)
            export VAULT_SECRET_PATH="$value"
            echo "📂 Updated secret path: $value"
            ;;
        *)
            echo "❌ Unknown configuration key: $key"
            echo "   Valid keys: VAULT_ADDR, VAULT_TOKEN, VAULT_MOUNT_PATH, VAULT_SECRET_PATH"
            return 1
            ;;
    esac
    
    # Save updated config
    vault_config_save
    echo "💾 Configuration saved successfully"
}

# Interactive configuration initialization
vault_config_init() {
    echo "🔧 SSH Vault Configuration Setup"
    echo "========================================"
    
    # Load existing config if available
    vault_config_load
    
    echo "📋 Current Configuration:"
    echo "   🌐 Vault Address: ${VAULT_ADDR:-[not set]}"
    echo "   📁 Mount Path: ${VAULT_MOUNT_PATH:-secret}"
    echo "   📂 Secret Path: ${VAULT_SECRET_PATH:-ssh}"
    echo
    
    # Prompt for Vault address
    read -p "🌐 Vault address [$VAULT_ADDR]: " addr
    export VAULT_ADDR="${addr:-$VAULT_ADDR}"
    
    # Prompt for Vault token
    read -s -p "🔑 Vault token: " token
    echo
    if [[ -n "$token" ]]; then
        export VAULT_TOKEN="$token"
    fi
    
    # Prompt for mount path
    read -p "📁 Vault mount path [${VAULT_MOUNT_PATH:-secret}]: " mount
    export VAULT_MOUNT_PATH="${mount:-${VAULT_MOUNT_PATH:-secret}}"
    
    # Prompt for secret path
    read -p "📂 SSH secrets base path [${VAULT_SECRET_PATH:-ssh}]: " path
    export VAULT_SECRET_PATH="${path:-${VAULT_SECRET_PATH:-ssh}}"
    
    echo
    echo "💾 Saving configuration..."
    # Save configuration
    vault_config_save
    
    echo "✅ Configuration saved to $SSH_VAULT_CONFIG_FILE"
    echo
    
    # Test connection
    echo "🔍 Testing vault connection..."
    if vault_test_connection; then
        echo "🎉 Setup complete! You can now use vault_ssh."
    else
        echo "❌ Setup failed - please check your configuration"
        return 1
    fi
}

# Test vault connectivity
vault_test_connection() {
    vault_config_load
    
    if [[ -z "$VAULT_ADDR" || -z "$VAULT_TOKEN" ]]; then
        echo "❌ Vault configuration incomplete. Run vault_config_init first."
        return 1
    fi
    
    echo "🔌 Testing connection to vault at $VAULT_ADDR..."
    
    # Test vault connection
    if vault status >/dev/null 2>&1; then
        echo "✅ Vault connection successful"
        return 0
    else
        echo "❌ Cannot connect to vault at $VAULT_ADDR"
        echo "   💡 Check network connectivity and vault server status"
        return 1
    fi
}

# Comprehensive vault validation function
vault_check() {
    echo "🔍 SSH Vault Configuration Check"
    echo "========================================"
    
    # Load configuration
    vault_config_load
    
    # Check configuration variables
    echo
    echo "📋 Configuration Status:"
    echo "   🌐 VAULT_ADDR: ${VAULT_ADDR:-❌ [NOT SET]}"
    echo "   🔑 VAULT_TOKEN: ${VAULT_TOKEN:+✅ [SET]}${VAULT_TOKEN:-❌ [NOT SET]}"
    echo "   📁 VAULT_MOUNT_PATH: ${VAULT_MOUNT_PATH:-secret}"
    echo "   📂 VAULT_SECRET_PATH: ${VAULT_SECRET_PATH:-ssh}"
    echo "   💾 Config file: ${SSH_VAULT_CONFIG_FILE:-$HOME/.ssh_vault_config}"
    
    # Check if configuration file exists
    echo
    echo "📁 File System Check:"
    if [[ -f "${SSH_VAULT_CONFIG_FILE:-$HOME/.ssh_vault_config}" ]]; then
        echo "   ✅ Configuration file exists"
    else
        echo "   ❌ Configuration file missing"
        echo "   💡 Run 'vault_config_init' to create it"
        return 1
    fi
    
    # Check required variables
    echo
    echo "🔧 Variable Validation:"
    local config_ok=true
    if [[ -z "$VAULT_ADDR" ]]; then
        echo "   ❌ VAULT_ADDR not set"
        config_ok=false
    else
        echo "   ✅ VAULT_ADDR is configured"
    fi
    
    if [[ -z "$VAULT_TOKEN" ]]; then
        echo "   ❌ VAULT_TOKEN not set"
        config_ok=false
    else
        echo "   ✅ VAULT_TOKEN is configured"
    fi
    
    if [[ "$config_ok" != "true" ]]; then
        echo
        echo "❌ Configuration incomplete."
        echo "💡 Run 'vault_config_init' to complete setup."
        return 1
    fi
    
    # Test vault connectivity
    echo
    echo "🔌 Connection Testing:"
    if vault status >/dev/null 2>&1; then
        echo "   ✅ Vault server is reachable"
    else
        echo "   ❌ Cannot reach vault server at $VAULT_ADDR"
        echo "   💡 Check network connectivity and server status"
        return 1
    fi
    
    # Test authentication
    echo "   🔐 Testing vault authentication..."
    if vault token lookup >/dev/null 2>&1; then
        echo "   ✅ Vault authentication successful"
        
        # Show token info
        local token_info
        token_info=$(vault token lookup -format=json 2>/dev/null)
        if [[ -n "$token_info" ]]; then
            local ttl policies
            ttl=$(echo "$token_info" | jq -r '.data.ttl // "unknown"' 2>/dev/null || echo "unknown")
            policies=$(echo "$token_info" | jq -r '.data.policies[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "unknown")
            echo "   ⏱️  Token TTL: ${ttl}s"
            echo "   🛡️  Token policies: $policies"
        fi
    else
        echo "   ❌ Vault authentication failed"
        echo "   💡 Check your VAULT_TOKEN or run 'vault auth'"
        return 1
    fi
    
    # Test secrets engine
    echo
    echo "🗄️  Secrets Engine Testing:"
    local mount_path="${VAULT_MOUNT_PATH:-secret}"
    
    # Try to access the specific secrets engine directly instead of listing all mounts
    # This avoids permission issues with sys/mounts endpoint
    local test_result
    test_result=$(vault kv list "$mount_path/" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "   ✅ Secrets engine '$mount_path' is accessible"
    elif [[ "$test_result" == *"permission denied"* ]]; then
        echo "   ❌ Permission denied accessing secrets engine '$mount_path'"
        echo "   💡 Your token may not have read permissions for this mount"
        return 1
    elif [[ "$test_result" == *"no handler for route"* || "$test_result" == *"unsupported path"* ]]; then
        echo "   ❌ Secrets engine '$mount_path' does not exist or is not a KV engine"
        echo "   💡 Check your VAULT_MOUNT_PATH configuration"
        return 1
    else
        echo "   ✅ Secrets engine '$mount_path' is accessible"
    fi
    
    # Test example secret path
    echo
    echo "📍 Path Information:"
    local test_path="${mount_path}/${VAULT_SECRET_PATH:-ssh}/example"
    echo "   🎯 Example secret path: $test_path"
    echo "   📝 To create a test secret:"
    echo "      vault kv put $test_path password='testpass'"
    echo "   🚀 To use with SSH:"
    echo "      vault_ssh hostname"
    
    # Check for sshpass
    echo
    echo "🔗 Dependencies:"
    if command -v sshpass >/dev/null 2>&1; then
        echo "   ✅ sshpass is available for password authentication"
    else
        echo "   ⚠️  sshpass not found - install for automatic password input"
        echo "   💡 Ubuntu/Debian: sudo apt install sshpass"
        echo "   💡 CentOS/RHEL: sudo yum install sshpass"
    fi
    
    echo
    echo "🎉 === Vault Check Complete ==="
    return 0
}

# Load configuration on script load
vault_config_load

# Get password from vault
vault_get_password() {
    local secret_path="$1"
    
    if [[ -z "$secret_path" ]]; then
        echo "Error: Secret path required"
        return 1
    fi
    
    # Ensure configuration is loaded
    vault_config_load
    
    if [[ -z "$VAULT_ADDR" || -z "$VAULT_TOKEN" ]]; then
        echo "Error: Vault not configured. Run vault_config_init first." >&2
        return 1
    fi
    
    # Retrieve password from vault (handles both KV v1 and v2)
    local password error_msg
    error_msg=$(vault kv get -field=password "$secret_path" 2>&1)
    
    if [[ $? -eq 0 && -n "$error_msg" ]]; then
        password="$error_msg"
        echo "$password"
        return 0
    else
        echo "❌ Could not retrieve password from vault path: $secret_path" >&2
        
        # Check for common error patterns and provide helpful messages
        if [[ "$error_msg" == *"permission denied"* || "$error_msg" == *"invalid token"* ]]; then
            echo "   🔑 Token may have expired or lacks permissions. Try:" >&2
            echo "   1️⃣  Renew token: vault token renew" >&2
            echo "   2️⃣  Re-authenticate: vault auth" >&2
            echo "   3️⃣  Reconfigure: vault_config_init" >&2
        elif [[ "$error_msg" == *"no secret exists"* || "$error_msg" == *"no value found"* ]]; then
            echo "   📝 Secret not found. Create it with:" >&2
            echo "   💡 vault kv put $secret_path password='your_password'" >&2
        else
            echo "   ⚠️  Vault error: $error_msg" >&2
        fi
        
        return 1
    fi
}

# Main SSH function using vault passwords
vault_ssh() {
    local target="$1"
    local custom_secret_path="$2"
    
    if [[ -z "$target" ]]; then
        echo "Usage: vault_ssh [user@]hostname [vault_secret_path]"
        return 1
    fi
    
    # Extract hostname from target
    local hostname
    if [[ "$target" == *"@"* ]]; then
        hostname="${target#*@}"
    else
        hostname="$target"
    fi
    
    # Determine secret path
    local secret_path
    if [[ -n "$custom_secret_path" ]]; then
        secret_path="$custom_secret_path"
    else
        vault_config_load
        secret_path="${VAULT_MOUNT_PATH:-secret}/${VAULT_SECRET_PATH:-ssh}/$hostname"
    fi
    
    # Check token validity before attempting to retrieve password
    if ! vault token lookup >/dev/null 2>&1; then
        echo "❌ Vault token is invalid or expired" >&2
        echo "   💡 Run 'vault auth' to authenticate or 'vault_config_init' to reconfigure" >&2
        echo "🔄 Falling back to standard SSH..." >&2
        ssh "$target"
        return $?
    fi
    
    echo "🔍 Retrieving password from vault: $secret_path"
    
    # Get password from vault
    local password
    password=$(vault_get_password "$secret_path")
    
    if [[ $? -eq 0 && -n "$password" ]]; then
        echo "🚀 Connecting to $target..."
        
        # Use sshpass to provide password to SSH
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$password" ssh "$target"
        else
            echo "⚠️  sshpass not found. Install sshpass for password authentication."
            echo "🔄 Falling back to standard SSH..."
            ssh "$target"
        fi
        
        # Clear password from memory
        unset password
    else
        echo "❌ Failed to retrieve password from vault. Falling back to standard SSH..."
        ssh "$target"
    fi
}

# Display usage information
vault_ssh_help() {
    cat << EOF
SSH Vault - SSH with HashiCorp Vault passwords

FUNCTIONS:
  vault_ssh [user@]hostname [vault_secret_path]
    SSH to hostname using password from vault
    
  vault_config_init
    Interactive setup of vault configuration
    
  vault_config_set KEY VALUE
    Set individual configuration parameters
    
  vault_get_password secret_path
    Retrieve password from vault path
    
  vault_test_connection
    Test vault connectivity
    
  vault_check
    Comprehensive vault configuration and connectivity check
    
  vault_ssh_help
    Display this help message

EXAMPLES:
  vault_ssh myserver
  vault_ssh user@myserver.com
  vault_ssh admin@db01 secret/database/admin
  
CONFIGURATION:
  Run 'vault_config_init' to set up vault connection parameters.
  
For more information, see README.md
EOF
}