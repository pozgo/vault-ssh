# SSH Vault

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-bash%2Fzsh-blue)](https://www.gnu.org/software/bash/)
[![HashiCorp Vault](https://img.shields.io/badge/HashiCorp-Vault-orange)](https://www.vaultproject.io/)

A secure shell extension for `.bashrc` and `.zshrc` that enables SSH connections using passwords and SSH keys stored in HashiCorp Vault. Never store SSH credentials in plain text again!

## Features

- 🔐 **Secure Credential Storage**: Retrieve SSH passwords and keys from HashiCorp Vault
- 🔑 **SSH Key Support**: Use SSH keys stored in Vault with automatic temporary file management
- 🛡️ **Security First**: Credentials never stored in shell history or temporary files
- 🔄 **Smart Authentication**: SSH key authentication with password fallback
- 🔍 **Comprehensive Diagnostics**: Built-in troubleshooting with `vault_check()`
- ⚡ **Easy Integration**: Simple sourcing into existing shell profiles
- 🎯 **Flexible Configuration**: Support for multiple Vault paths and configurations

## Prerequisites

### Required Dependencies
- **HashiCorp Vault CLI**: [Installation Guide](https://developer.hashicorp.com/vault/docs/install)
- **Bash or Zsh shell**
- **SSH client** (standard on most systems)

### Optional Dependencies
- **sshpass**: For automatic password authentication
  ```bash
  # Ubuntu/Debian
  sudo apt install sshpass
  
  # CentOS/RHEL/Fedora
  sudo dnf install sshpass
  
  # macOS
  brew install hudochenkov/sshpass/sshpass
  ```
- **jq**: For enhanced token information display
  ```bash
  # Ubuntu/Debian
  sudo apt install jq
  
  # CentOS/RHEL/Fedora
  sudo dnf install jq
  
  # macOS
  brew install jq
  ```

### Vault Requirements
- HashiCorp Vault server (local or remote)
- Valid authentication token with read access to KV secrets engine
- KV secrets engine mounted (v1 or v2)

## Quick Start

### 1. Download and Install

```bash
# Clone the repository
git clone https://github.com/pozgo/vault-ssh.git
cd vault-ssh

# Or download directly
wget https://raw.githubusercontent.com/pozgo/vault-ssh/main/ssh_vault.sh
```

### 2. Add to Shell Profile

```bash
# For Bash users
echo "source $(pwd)/ssh_vault.sh" >> ~/.bashrc
source ~/.bashrc

# For Zsh users
echo "source $(pwd)/ssh_vault.sh" >> ~/.zshrc
source ~/.zshrc
```

### 3. Configure Vault Connection

```bash
# Interactive configuration setup
vault_config_init

# Verify everything is working
vault_check
```

### 4. Store SSH Passwords in Vault

```bash
# Store password for a server
vault kv put ssh-auth/hosts/myserver auth_type="password" username="admin" password="your_secure_password"

# Store SSH key authentication
vault kv put ssh-auth/hosts/myserver auth_type="key" username="admin" key_ref="shared/admin-key"

# Store both password and SSH key (SSH key tried first)
vault kv put ssh-auth/hosts/myserver auth_type="both" username="admin" password="backup_password" key_ref="shared/admin-key"
```

### 5. Connect to Servers

```bash
# Basic connection (uses default path)
vault_ssh user@myserver

# With custom secret path
vault_ssh user@database ssh-auth/hosts/database
```

## Configuration

### Initial Setup

Run the interactive configuration wizard:

```bash
vault_config_init
```

This will prompt for:
- **Vault Address**: Your Vault server URL (e.g., `https://vault.company.com:8200`)
- **Authentication Token**: Your Vault token with appropriate permissions
- **Mount Path**: Secrets engine mount point (default: `ssh-auth`)
- **Secret Path**: Base path for SSH secrets (default: `hosts`)

### Manual Configuration

Set individual configuration parameters:

```bash
vault_config_set VAULT_ADDR "https://vault.example.com:8200"
vault_config_set VAULT_TOKEN "hvs.your_token_here"
vault_config_set VAULT_MOUNT_PATH "ssh-auth"
vault_config_set VAULT_SECRET_PATH "hosts"
```

### Configuration File

Configuration is stored in `~/.ssh_vault_config`:

```bash
# Example configuration file content
VAULT_ADDR=https://vault.example.com:8200
VAULT_TOKEN=hvs.your_token_here
VAULT_MOUNT_PATH=ssh-auth
VAULT_SECRET_PATH=hosts
SSH_TEMP_KEY_DIR=/tmp/ssh_vault_keys
```

## Functions Reference

### vault_ssh()

Primary function for SSH connections with Vault-stored passwords.

**Syntax:**
```bash
vault_ssh [user@]hostname [vault_secret_path] [ssh_options]
```

**Examples:**
```bash
# Basic usage
vault_ssh user@server.example.com

# With custom secret path
vault_ssh admin@database ssh-auth/hosts/database

# With SSH options
vault_ssh user@server -p 2222 -o StrictHostKeyChecking=no
```

**Behavior:**
- Retrieves authentication details from Vault using the specified or default path
- Attempts SSH key authentication first, falls back to password if needed
- Establishes SSH connection with automatic credential handling
- Falls back to standard SSH if Vault operations fail
- Supports all standard SSH options and flags

### vault_config_init()

Interactive configuration setup wizard.

```bash
vault_config_init
```

Guides you through:
- Vault server address configuration
- Token authentication setup
- Secrets engine path configuration
- Configuration file creation

### vault_config_set()

Set individual configuration parameters.

**Syntax:**
```bash
vault_config_set VARIABLE value
```

**Examples:**
```bash
vault_config_set VAULT_ADDR "https://new-vault.example.com:8200"
vault_config_set VAULT_TOKEN "hvs.new_token"
vault_config_set VAULT_MOUNT_PATH "ssh-auth"
vault_config_set VAULT_SECRET_PATH "hosts"
vault_config_set SSH_TEMP_KEY_DIR "/tmp/ssh_vault_keys"
```

### vault_get_password()

Utility function to retrieve passwords from Vault.

**Syntax:**
```bash
vault_get_password secret_path
```

**Examples:**
```bash
# Retrieve password and use in variable
password=$(vault_get_password ssh-auth/hosts/myserver)

# Direct usage in commands
echo $(vault_get_password ssh-auth/hosts/database)
```

### vault_check()

Comprehensive diagnostic function for troubleshooting.

```bash
vault_check
```

**Diagnostic Features:**
- ✅ Configuration file validation
- 🔗 Vault server connectivity test
- 🎫 Token validity and expiration check
- 🗂️ Secrets engine accessibility verification
- 📦 Dependency availability check (sshpass, jq)
- 💡 Remediation suggestions for common issues
- 📝 Example commands for setup and testing

### vault_test_connection()

Quick Vault connectivity test.

```bash
vault_test_connection
```

Returns clear pass/fail status with specific error messages.

## Usage Patterns

### Default Path Structure

By default, SSH credentials are stored using this path pattern:
```
{VAULT_MOUNT_PATH}/{VAULT_SECRET_PATH}/{hostname}
```

**Example:**
- Mount path: `ssh-auth`
- Secret path: `hosts`
- Hostname: `web01.example.com`
- Full path: `ssh-auth/hosts/web01.example.com`

### Custom Path Structure

You can override the default path for specific connections:

```bash
# Store credentials in custom location
vault kv put ssh-auth/production/web auth_type="both" username="admin" password="prod_password" key_ref="shared/prod-key"

# Use custom path when connecting
vault_ssh admin@web01 ssh-auth/production/web
```

### Environment Variables

All configuration can be overridden with environment variables:

```bash
export VAULT_ADDR="https://vault.example.com:8200"
export VAULT_TOKEN="hvs.your_token"
export VAULT_MOUNT_PATH="ssh-auth"
export VAULT_SECRET_PATH="hosts"
export SSH_TEMP_KEY_DIR="/tmp/ssh_vault_keys"
export SSH_VAULT_CONFIG_FILE="~/.my_vault_config"
```

## Troubleshooting

### Quick Diagnostics

Always start with the comprehensive check:

```bash
vault_check
```

This will identify most common issues and provide specific remediation steps.

### Common Issues and Solutions

#### 🔐 Authentication Issues

**Token Expired/Invalid:**
```bash
# Check token status
vault token lookup

# Renew token
vault token renew

# Re-authenticate if needed
vault auth -method=userpass username=yourusername
```

**Permission Denied:**
```bash
# Check token capabilities
vault token capabilities ssh-auth/hosts/myserver

# Verify policy allows read access
vault policy read your-policy-name
```

#### 🌐 Connection Issues

**Vault Server Unreachable:**
```bash
# Test connectivity
curl -k $VAULT_ADDR/v1/sys/health

# Check DNS resolution
nslookup vault.example.com

# Verify firewall/network access
telnet vault.example.com 8200
```

**TLS Certificate Issues:**
```bash
# Skip TLS verification (not recommended for production)
export VAULT_SKIP_TLS_VERIFY=true

# Or add certificate to trust store
sudo cp vault-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

#### 🗝️ Secret Issues

**Secret Not Found:**
```bash
# List available secrets
vault kv list ssh-auth/hosts/

# Create missing secret
vault kv put ssh-auth/hosts/myserver auth_type="password" username="admin" password="your_password"

# Check secret exists
vault kv get ssh-auth/hosts/myserver
```

**Wrong Secret Engine Version:**
```bash
# Check if using KV v2 (data/ prefix needed)
vault kv get -mount=ssh-auth hosts/myserver

# Or adjust mount path in configuration  
vault_config_set VAULT_MOUNT_PATH "ssh-auth"
```

#### 🔧 SSH Issues

**Still Prompts for Password:**
1. Check authentication method: `vault kv get ssh-auth/hosts/hostname`
2. Install sshpass: `sudo apt install sshpass`
3. Verify Vault connectivity: `vault_check`
4. Test credential retrieval: `vault_get_password ssh-auth/hosts/hostname`
5. Verify SSH key authentication is properly configured

**Connection Timeouts:**
```bash
# Use SSH options for faster timeout
vault_ssh user@server -o ConnectTimeout=10 -o ConnectionAttempts=3
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Enable debug mode for vault_ssh
DEBUG=1 vault_ssh user@hostname

# Enable Vault CLI debug output
export VAULT_LOG_LEVEL=debug
vault_check
```

## Security Considerations

### 🔒 Security Best Practices

1. **Token Management:**
   - Use tokens with minimal required permissions
   - Set appropriate TTL (Time To Live) on tokens
   - Regularly rotate tokens
   - Never share tokens in plain text

2. **Configuration Security:**
   - Protect configuration file: `chmod 600 ~/.ssh_vault_config`
   - Consider using Vault agent for token management
   - Use environment variables in shared environments

3. **Network Security:**
   - Always use HTTPS for Vault communication
   - Verify TLS certificates in production
   - Consider VPN or private networks for Vault access

4. **Secret Management:**
   - Use descriptive but not revealing secret paths
   - Implement secret rotation policies
   - Monitor secret access logs
   - Delete unused secrets promptly

### 🛡️ Built-in Security Features

- **No History Pollution**: Passwords never appear in shell history
- **Temporary Variable Cleanup**: All password variables are unset after use
- **Graceful Fallback**: Falls back to standard SSH if Vault fails
- **Error Handling**: Comprehensive error messages without exposing sensitive data

## Examples

### Complete Setup Workflow

```bash
# 1. Install dependencies
sudo apt update && sudo apt install sshpass jq

# 2. Download and setup SSH Vault
git clone https://github.com/pozgo/vault-ssh.git
cd vault-ssh
echo "source $(pwd)/ssh_vault.sh" >> ~/.bashrc
source ~/.bashrc

# 3. Configure Vault connection
vault_config_init
# Follow prompts to enter:
# - Vault Address: https://vault.company.com:8200
# - Token: hvs.your_vault_token
# - Mount Path: ssh-auth
# - Secret Path: hosts

# 4. Verify configuration
vault_check

# 5. Store some credentials
vault kv put ssh-auth/hosts/web01.company.com auth_type="both" username="admin" password="web_password" key_ref="shared/admin-key"
vault kv put ssh-auth/hosts/db01.company.com auth_type="key" username="dbadmin" key_ref="shared/db-key"
vault kv put ssh-auth/hosts/10.0.1.100 auth_type="password" username="root" password="server_password"

# 6. Test connections
vault_ssh admin@web01.company.com
vault_ssh root@db01.company.com
vault_ssh user@10.0.1.100
```

### Advanced Usage Patterns

```bash
# Using different Vault paths for different environments
vault kv put ssh-auth/production/web01 auth_type="key" username="admin" key_ref="shared/prod-key"
vault kv put ssh-auth/staging/web01 auth_type="both" username="admin" password="stage_pass" key_ref="shared/stage-key"

# Connect to different environments
vault_ssh admin@web01.prod ssh-auth/production/web01
vault_ssh admin@web01.stage ssh-auth/staging/web01

# Batch operations
for host in web01 web02 web03; do
  vault kv put ssh-auth/hosts/$host auth_type="password" username="admin" password="$(openssl rand -base64 32)"
done

# Using with SSH config aliases
# ~/.ssh/config:
# Host prod-web
#   HostName web01.production.com
#   User admin
#   Port 2222

vault_ssh prod-web ssh-auth/production/web01
```

### Integration Examples

**With Ansible:**
```bash
# Use vault_get_password in Ansible inventory
ansible_ssh_pass=$(vault_get_password ssh-auth/hosts/myserver) ansible-playbook playbook.yml
```

**With Scripts:**
```bash
#!/bin/bash
# Automated server maintenance script

servers=("web01" "web02" "db01")
for server in "${servers[@]}"; do
  echo "Connecting to $server..."
  vault_ssh admin@$server "uptime && df -h"
done
```

**With tmux/screen:**
```bash
# Create tmux session with multiple server connections
tmux new-session -d -s servers
tmux split-window -h 'vault_ssh admin@web01'
tmux split-window -v 'vault_ssh admin@web02'
tmux attach-session -t servers
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Run the test suite: `./tests/run_tests.sh`
5. Submit a pull request

### Running Tests

```bash
# Run all tests
cd tests
./test_config.sh
./test_vault.sh
./test_ssh.sh

# Run specific test
bash -x test_vault.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 **Documentation**: Check this README and inline function help
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/pozgo/vault-ssh/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/pozgo/vault-ssh/discussions)
- 🤝 **Community**: Join our discussions for help and tips

## Changelog

### Version 1.0.0
- Initial release with core functionality
- Interactive configuration setup
- Comprehensive diagnostic tools
- Full test coverage
- Security-focused design

---

**⚠️ Security Notice**: This tool handles sensitive authentication credentials. Always follow security best practices and regularly audit your Vault policies and token permissions.