#!/bin/bash

# Test SSH integration functions

# Source the main script
source "$(dirname "$0")/../ssh_vault.sh"

# Mock commands for testing
sshpass() {
    echo "Mock sshpass called with: $*"
    return 0
}

ssh() {
    echo "Mock ssh called with: $*"
    return 0
}

vault() {
    case "$1 $2" in
        "kv get")
            if [[ "$4" == "secret/ssh/testserver" ]]; then
                echo "testpassword"
                return 0
            else
                return 1
            fi
            ;;
        "status")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Override command check to simulate sshpass availability
command() {
    if [[ "$1" == "-v" && "$2" == "sshpass" ]]; then
        return 0
    fi
    return 1
}

# Test vault_ssh function with default path
test_ssh_default_path() {
    echo "Testing vault_ssh with default path..."
    
    # Set up test config
    export VAULT_ADDR="https://vault.test.com:8200"
    export VAULT_TOKEN="test-token"
    export VAULT_MOUNT_PATH="secret"
    export VAULT_SECRET_PATH="ssh"
    
    # Test SSH with default path
    output=$(vault_ssh "testserver" 2>&1)
    
    if [[ "$output" != *"Mock sshpass called with: -p testpassword ssh testserver"* ]]; then
        echo "FAIL: SSH not called correctly with default path"
        echo "Output: $output"
        return 1
    fi
    
    echo "PASS: vault_ssh works with default path"
    return 0
}

# Test vault_ssh function with custom path
test_ssh_custom_path() {
    echo "Testing vault_ssh with custom path..."
    
    # Set up test config
    export VAULT_ADDR="https://vault.test.com:8200"
    export VAULT_TOKEN="test-token"
    
    # Test SSH with custom path
    output=$(vault_ssh "user@testserver" "secret/ssh/testserver" 2>&1)
    
    if [[ "$output" != *"Mock sshpass called with: -p testpassword ssh user@testserver"* ]]; then
        echo "FAIL: SSH not called correctly with custom path"
        echo "Output: $output"
        return 1
    fi
    
    echo "PASS: vault_ssh works with custom path"
    return 0
}

# Test vault_ssh fallback to standard SSH
test_ssh_fallback() {
    echo "Testing vault_ssh fallback..."
    
    # Clear config to trigger fallback
    unset VAULT_ADDR VAULT_TOKEN
    
    # Test SSH fallback
    output=$(vault_ssh "testserver" 2>&1)
    
    if [[ "$output" != *"Mock ssh called with: testserver"* ]]; then
        echo "FAIL: SSH fallback not working"
        echo "Output: $output"
        return 1
    fi
    
    echo "PASS: vault_ssh fallback works correctly"
    return 0
}

# Test invalid usage
test_ssh_invalid_usage() {
    echo "Testing vault_ssh invalid usage..."
    
    if vault_ssh 2>/dev/null; then
        echo "FAIL: Should reject empty target"
        return 1
    fi
    
    echo "PASS: Invalid usage handled correctly"
    return 0
}

# Run tests
echo "Running SSH integration tests..."

test_ssh_default_path
test_ssh_custom_path
test_ssh_fallback
test_ssh_invalid_usage

echo "SSH integration tests completed."