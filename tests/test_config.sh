#!/bin/bash

# Test configuration functions

# Source the main script
source "$(dirname "$0")/../ssh_vault.sh"

# Test variables
TEST_CONFIG_FILE="/tmp/test_ssh_vault_config"
SSH_VAULT_CONFIG_FILE="$TEST_CONFIG_FILE"

# Cleanup function
cleanup() {
    rm -f "$TEST_CONFIG_FILE"
}

# Test vault_config_set function
test_config_set() {
    echo "Testing vault_config_set..."
    
    # Set test values
    vault_config_set VAULT_ADDR "https://vault.test.com:8200"
    vault_config_set VAULT_TOKEN "test-token-123"
    vault_config_set VAULT_MOUNT_PATH "secret"
    vault_config_set VAULT_SECRET_PATH "ssh"
    
    # Verify config file was created
    if [[ ! -f "$TEST_CONFIG_FILE" ]]; then
        echo "FAIL: Config file not created"
        return 1
    fi
    
    # Load config and verify values
    vault_config_load
    
    if [[ "$VAULT_ADDR" != "https://vault.test.com:8200" ]]; then
        echo "FAIL: VAULT_ADDR not set correctly"
        return 1
    fi
    
    if [[ "$VAULT_TOKEN" != "test-token-123" ]]; then
        echo "FAIL: VAULT_TOKEN not set correctly"
        return 1
    fi
    
    echo "PASS: vault_config_set works correctly"
    return 0
}

# Test vault_config_load function
test_config_load() {
    echo "Testing vault_config_load..."
    
    # Create test config file
    cat > "$TEST_CONFIG_FILE" << EOF
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="example-token"
export VAULT_MOUNT_PATH="kv"
export VAULT_SECRET_PATH="passwords"
EOF
    
    # Load config
    vault_config_load
    
    # Verify values
    if [[ "$VAULT_ADDR" != "https://vault.example.com:8200" ]]; then
        echo "FAIL: VAULT_ADDR not loaded correctly"
        return 1
    fi
    
    echo "PASS: vault_config_load works correctly"
    return 0
}

# Test invalid config key
test_invalid_config_key() {
    echo "Testing invalid config key..."
    
    if vault_config_set INVALID_KEY "value" 2>/dev/null; then
        echo "FAIL: Should reject invalid config key"
        return 1
    fi
    
    echo "PASS: Invalid config key rejected correctly"
    return 0
}

# Run tests
echo "Running configuration tests..."
cleanup

test_config_set
test_config_load  
test_invalid_config_key

cleanup
echo "Configuration tests completed."