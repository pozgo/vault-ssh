#!/bin/bash

# SSH Vault - Shell functions for SSH with HashiCorp Vault passwords

# SSH Vault Configuration Management

# Default configuration file location
SSH_VAULT_CONFIG_FILE="${SSH_VAULT_CONFIG_FILE:-$HOME/.ssh_vault_config}"

# Default temporary key directory
SSH_TEMP_KEY_DIR="${SSH_TEMP_KEY_DIR:-/tmp/ssh_vault_keys}"

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
export VAULT_MOUNT_PATH="${VAULT_MOUNT_PATH:-ssh-passwords}"
export VAULT_SECRET_PATH="${VAULT_SECRET_PATH:-hosts}"
export SSH_TEMP_KEY_DIR="${SSH_TEMP_KEY_DIR:-/tmp/ssh_vault_keys}"
EOF
    chmod 600 "$SSH_VAULT_CONFIG_FILE"
}

# Set individual configuration parameter
vault_config_set() {
    local key="$1"
    local value="$2"
    
    if [[ -z "$key" || -z "$value" ]]; then
        echo "📖 Usage: vault_config_set KEY VALUE"
        echo "   Valid keys: VAULT_ADDR, VAULT_TOKEN, VAULT_MOUNT_PATH, VAULT_SECRET_PATH, SSH_TEMP_KEY_DIR"
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
        SSH_TEMP_KEY_DIR)
            export SSH_TEMP_KEY_DIR="$value"
            echo "🗂️  Updated temp key directory: $value"
            ;;
        *)
            echo "❌ Unknown configuration key: $key"
            echo "   Valid keys: VAULT_ADDR, VAULT_TOKEN, VAULT_MOUNT_PATH, VAULT_SECRET_PATH, SSH_TEMP_KEY_DIR"
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

# Get secret with auth type detection from vault
vault_get_secret() {
    local secret_path="$1"
    
    if [[ -z "$secret_path" ]]; then
        echo "Error: Secret path required" >&2
        return 1
    fi
    
    # Ensure configuration is loaded
    vault_config_load
    
    if [[ -z "$VAULT_ADDR" || -z "$VAULT_TOKEN" ]]; then
        echo "Error: Vault not configured. Run vault_config_init first." >&2
        return 1
    fi
    
    # Check token validity
    if ! vault token lookup >/dev/null 2>&1; then
        echo "Error: Vault token is invalid or expired" >&2
        return 1
    fi
    
    # Retrieve secret from vault
    local secret_json error_msg
    secret_json=$(vault kv get -format=json "$secret_path" 2>&1)
    
    if [[ $? -eq 0 && -n "$secret_json" ]]; then
        # Extract data from JSON
        local auth_type username password key_ref
        auth_type=$(echo "$secret_json" | jq -r '.data.data.auth_type // "password"' 2>/dev/null)
        username=$(echo "$secret_json" | jq -r '.data.data.username // "root"' 2>/dev/null)
        password=$(echo "$secret_json" | jq -r '.data.data.password // empty' 2>/dev/null)
        key_ref=$(echo "$secret_json" | jq -r '.data.data.key_ref // empty' 2>/dev/null)
        
        # Return structured data
        echo "{\"auth_type\":\"$auth_type\",\"username\":\"$username\",\"password\":\"$password\",\"key_ref\":\"$key_ref\"}"
        return 0
    else
        echo "❌ Could not retrieve secret from vault path: $secret_path" >&2
        
        # Check for common error patterns
        if [[ "$secret_json" == *"permission denied"* || "$secret_json" == *"invalid token"* ]]; then
            echo "   🔑 Token may have expired or lacks permissions. Try:" >&2
            echo "   1️⃣  Renew token: vault token renew" >&2
            echo "   2️⃣  Re-authenticate: vault auth" >&2
            echo "   3️⃣  Reconfigure: vault_config_init" >&2
        elif [[ "$secret_json" == *"no secret exists"* || "$secret_json" == *"no value found"* ]]; then
            echo "   📝 Secret not found. Create it with:" >&2
            echo "   💡 vault kv put $secret_path auth_type='password' username='user' password='pass'" >&2
        else
            echo "   ⚠️  Vault error: $secret_json" >&2
        fi
        
        return 1
    fi
}

# Get SSH key from vault and create temporary key file
vault_get_ssh_key() {
    local key_path="$1"
    local hostname="$2"
    
    if [[ -z "$key_path" || -z "$hostname" ]]; then
        echo "Error: Key path and hostname required" >&2
        return 1
    fi
    
    # Ensure configuration is loaded
    vault_config_load
    
    if [[ -z "$VAULT_ADDR" || -z "$VAULT_TOKEN" ]]; then
        echo "Error: Vault not configured. Run vault_config_init first." >&2
        return 1
    fi
    
    # Create temporary key directory
    local temp_dir="${SSH_TEMP_KEY_DIR:-/tmp/ssh_vault_keys}"
    mkdir -p "$temp_dir" 2>/dev/null
    chmod 700 "$temp_dir" 2>/dev/null
    
    # Create unique temporary key file
    local timestamp=$(date +%s)
    local temp_key_file="$temp_dir/${hostname}_${timestamp}.key"
    
    # Retrieve private key from vault
    local private_key error_msg
    private_key=$(vault kv get -field=private_key "$key_path" 2>&1)
    
    if [[ $? -eq 0 && -n "$private_key" ]]; then
        # Write key to temporary file with secure permissions
        echo "$private_key" > "$temp_key_file"
        chmod 600 "$temp_key_file"
        
        # Validate key format
        if ssh-keygen -l -f "$temp_key_file" >/dev/null 2>&1; then
            echo "$temp_key_file"
            return 0
        else
            rm -f "$temp_key_file"
            echo "Error: Invalid SSH key format" >&2
            return 1
        fi
    else
        echo "❌ Could not retrieve SSH key from vault path: $key_path" >&2
        
        if [[ "$error_msg" == *"permission denied"* ]]; then
            echo "   🔑 Token lacks permissions for key path" >&2
        elif [[ "$error_msg" == *"no secret exists"* ]]; then
            echo "   📝 SSH key not found at path: $key_path" >&2
        else
            echo "   ⚠️  Vault error: $error_msg" >&2
        fi
        
        return 1
    fi
}

# Cleanup temporary SSH key files
vault_cleanup_temp_keys() {
    local temp_dir="${SSH_TEMP_KEY_DIR:-/tmp/ssh_vault_keys}"
    local max_age="${1:-3600}"  # Default: 1 hour
    
    if [[ -d "$temp_dir" ]]; then
        # Remove files older than max_age seconds
        find "$temp_dir" -name "*.key" -type f -mmin "+$((max_age/60))" -delete 2>/dev/null
        
        # Remove empty directory if no keys remain
        if [[ -z "$(ls -A "$temp_dir" 2>/dev/null)" ]]; then
            rmdir "$temp_dir" 2>/dev/null
        fi
    fi
}

# Main SSH function with dual authentication support (password and SSH key)
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
    
    # Determine secret path - now using hosts/ structure
    local secret_path
    if [[ -n "$custom_secret_path" ]]; then
        secret_path="$custom_secret_path"
    else
        vault_config_load
        secret_path="${VAULT_MOUNT_PATH:-ssh-passwords}/hosts/$hostname"
    fi
    
    # Check token validity
    if ! vault token lookup >/dev/null 2>&1; then
        echo "❌ Vault token is invalid or expired" >&2
        echo "   💡 Run 'vault auth' to authenticate or 'vault_config_init' to reconfigure" >&2
        echo "🔄 Falling back to standard SSH..." >&2
        ssh "$target"
        return $?
    fi
    
    echo "🔍 Retrieving authentication details from vault: $secret_path"
    
    # Get secret with auth type detection
    local secret_json auth_type username password key_ref
    secret_json=$(vault_get_secret "$secret_path")
    
    if [[ $? -ne 0 || -z "$secret_json" ]]; then
        echo "❌ Failed to retrieve authentication details from vault. Falling back to standard SSH..."
        ssh "$target"
        return $?
    fi
    
    # Parse authentication details
    auth_type=$(echo "$secret_json" | jq -r '.auth_type // "password"' 2>/dev/null)
    username=$(echo "$secret_json" | jq -r '.username // "root"' 2>/dev/null)
    password=$(echo "$secret_json" | jq -r '.password // empty' 2>/dev/null)
    key_ref=$(echo "$secret_json" | jq -r '.key_ref // empty' 2>/dev/null)
    
    # Determine SSH target with username
    local ssh_target="$target"
    if [[ "$target" != *"@"* && -n "$username" ]]; then
        ssh_target="${username}@${hostname}"
    fi
    
    echo "🔐 Available authentication methods: $([ -n "$key_ref" ] && echo "SSH key" || echo "")$([ -n "$key_ref" ] && [ -n "$password" ] && echo ", ")$([ -n "$password" ] && echo "password")"
    
    # Priority: SSH Key first, then password fallback
    # Try SSH key authentication first if available
    if [[ -n "$key_ref" ]]; then
        echo "🔑 Attempting SSH key authentication: $key_ref"
        
        # Resolve key reference to full path
        local key_path="${VAULT_MOUNT_PATH:-ssh-passwords}/keys/$key_ref"
        
        # Get SSH key and create temporary file
        local temp_key_file
        temp_key_file=$(vault_get_ssh_key "$key_path" "$hostname")
        
        if [[ $? -eq 0 && -n "$temp_key_file" ]]; then
            echo "🚀 Connecting to $ssh_target with SSH key authentication..."
            
            # Setup cleanup trap
            trap "rm -f '$temp_key_file'; vault_cleanup_temp_keys" EXIT INT TERM
            
            # Try SSH key with timeout
            if ssh -i "$temp_key_file" -o PasswordAuthentication=no -o ConnectTimeout=10 "$ssh_target"; then
                # Success with SSH key
                rm -f "$temp_key_file"
                vault_cleanup_temp_keys
                return 0
            else
                echo "⚠️  SSH key authentication failed"
                rm -f "$temp_key_file"
                vault_cleanup_temp_keys
                
                # Continue to password fallback if available
                if [[ -n "$password" ]]; then
                    echo "🔄 Falling back to password authentication..."
                else
                    echo "❌ No password available for fallback. Using standard SSH..."
                    ssh "$ssh_target"
                    return $?
                fi
            fi
        else
            echo "❌ Failed to retrieve SSH key from vault"
            
            # Continue to password fallback if available
            if [[ -n "$password" ]]; then
                echo "🔄 Falling back to password authentication..."
            else
                echo "❌ No password available for fallback. Using standard SSH..."
                ssh "$ssh_target"
                return $?
            fi
        fi
    fi
    
    # Password authentication (either primary choice or fallback)
    if [[ -n "$password" ]]; then
        if [[ -n "$key_ref" ]]; then
            echo "🔐 Using password authentication as fallback..."
        else
            echo "🔐 Using password authentication (no SSH key configured)..."
        fi
        
        echo "🚀 Connecting to $ssh_target with password authentication..."
        
        if command -v sshpass >/dev/null 2>&1; then
            sshpass -p "$password" ssh "$ssh_target"
        else
            echo "⚠️  sshpass not found. Install sshpass for password authentication."
            echo "🔄 Falling back to standard SSH..."
            ssh "$ssh_target"
        fi
        
        # Clear password from memory
        unset password
    else
        # No authentication methods available
        echo "❌ No authentication methods available (no SSH key or password). Using standard SSH..."
        ssh "$ssh_target"
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