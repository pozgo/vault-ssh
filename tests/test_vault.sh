#!/bin/bash

# Test vault integration functions

# Source the main script
source "$(dirname "$0")/../ssh_vault.sh"

# Mock vault command for testing
vault() {
    case "$1 $2" in
        "kv get")
            # Mock successful password retrieval
            if [[ "$4" == "secret/ssh/testserver" ]]; then
                echo "mypassword123"
                return 0
            else
                return 1
            fi
            ;;
        "status")
            # Mock vault status check
            return 0
            ;;
        *)
            echo "Mock vault: $*"
            return 1
            ;;
    esac
}

# Test vault_get_password function
test_get_password() {
    echo "Testing vault_get_password..."
    
    # Set up test config
    export VAULT_ADDR="https://vault.test.com:8200"
    export VAULT_TOKEN="test-token"
    
    # Test successful password retrieval
    password=$(vault_get_password "secret/ssh/testserver")
    if [[ "$password" != "mypassword123" ]]; then
        echo "FAIL: Password not retrieved correctly"
        return 1
    fi
    
    # Test non-existent secret
    if vault_get_password "secret/ssh/nonexistent" 2>/dev/null; then
        echo "FAIL: Should fail for non-existent secret"
        return 1
    fi
    
    echo "PASS: vault_get_password works correctly"
    return 0
}

# Test vault_test_connection function
test_vault_connection() {
    echo "Testing vault_test_connection..."
    
    # Set up test config
    export VAULT_ADDR="https://vault.test.com:8200"
    export VAULT_TOKEN="test-token"
    
    if ! vault_test_connection >/dev/null 2>&1; then
        echo "FAIL: Vault connection test failed"
        return 1
    fi
    
    echo "PASS: vault_test_connection works correctly"
    return 0
}

# Test missing configuration
test_missing_config() {
    echo "Testing missing configuration..."
    
    # Clear config
    unset VAULT_ADDR VAULT_TOKEN
    
    if vault_get_password "secret/ssh/test" 2>/dev/null; then
        echo "FAIL: Should fail with missing configuration"
        return 1
    fi
    
    echo "PASS: Missing configuration handled correctly"
    return 0
}

# Run tests
echo "Running vault integration tests..."

test_get_password
test_vault_connection
test_missing_config

echo "Vault integration tests completed."