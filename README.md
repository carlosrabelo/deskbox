# Deskbox - Remote Desktop Environment

Docker container with Debian 13 (Trixie) + Xfce4 + XRDP for remote access via Remote Desktop Protocol.

## Features

- **Base**: Debian 13 (Trixie) - Testing release
- **Desktop Environment**: Xfce4 (with auto-configuration on first login)
- **Remote Access**:
  - XRDP (port 3389) - Remote Desktop Protocol
  - SSH (port 2222) - Secure Shell access
- **Backend**: xorgxrdp (native Xorg)
- **Multiple Users**: Full support (simultaneous sessions)
- **Default User**: deskbox (UID 1000)
- **Hostname**: deskbox
- **Timezone**: America/Cuiaba
- **Persistence**: All home directories in `/mnt/deskbox/home`
- **Healthcheck**: Automatic monitoring of XRDP service
- **Logging**: Structured logs for startup and XRDP events
- **Pre-installed Tools**: git, vim, htop, tmux, tree, and more
- **Custom Profile**: Useful aliases and colorful terminal prompt

## Quick Start

### 1. Configure Environment (Required)

Copy the example configuration and customize:

```bash
cp .env.example .env
```

Then edit `.env` to set your values:

```bash
# Docker Hub Configuration
DOCKER_USER=carlosrabelo
IMAGE_NAME=deskbox
VERSION=0.0.1

# User Configuration
USER_PASSWORD=your_secure_password_here

# System Configuration
TZ=America/Cuiaba
```

**IMPORTANT**: Never commit the `.env` file to Git!

### 2. Initialize Directories (First time)

```bash
make init CTX=hostname
```

### 3. Build Image

```bash
make build CTX=hostname
```

### 4. Start Container

```bash
make start CTX=hostname
```

### 5. Connect to Deskbox

**Option 1: RDP (Graphical Desktop)**

Use an RDP client (such as Remmina, Microsoft Remote Desktop, or rdesktop):

```bash
# Linux
rdesktop -u deskbox -p your_password hostname:3389

# Or with Remmina
# Host: hostname:3389
# User: deskbox
# Password: the one you defined in .env
```

**Option 2: SSH (Terminal Access)**

Connect via SSH for command-line access:

```bash
# SSH access
ssh -p 2222 deskbox@hostname

# Or with SCP to transfer files
scp -P 2222 file.txt deskbox@hostname:/home/deskbox/
```

## Available Make Commands

| Command | Description |
|---------|-----------|
| `make init` | Initialize directory structure on remote host |
| `make build` | Build Docker image (creates VERSION and latest tags) |
| `make push` | Push images to Docker Hub (VERSION and latest) |
| `make start` | Start container |
| `make stop` | Stop container |
| `make restart` | Restart container |
| `make ps` | List running containers |
| `make logs` | Display Docker Compose logs in real-time |
| `make view-logs` | View Aurora startup and XRDP logs |
| `make sessions` | Show active user sessions |
| `make backup` | Create backup of /mnt/deskbox/home |
| `make exec SVC=deskbox` | Open shell in container |
| `make config` | Display Docker Compose configuration |
| `make clean` | Remove local Docker images (current version) |
| `make clean-all` | Stop containers and remove all project images |

### Management Scripts

| Script | Description |
|--------|-----------|
| `./scripts/log-rotation.sh` | Rotate and manage log files |



All commands accept `CTX=<context>` to specify the remote Docker host and can override variables from `.env`.

## Multiple Users

The container works like a normal Debian system - you can add as many users as you need!

### Default User

- **User**: deskbox
- **UID**: 1000
- **Password**: Defined via `.env` (`USER_PASSWORD` variable)

### Adding New Users

Like a normal Debian system, use native commands:

**Method 1: Using `adduser` (Recommended - Interactive)**

```bash
# Enter the container
make exec SVC=deskbox CTX=hostname

# Add the user (Debian interactive command)
adduser john

# This will:
# 1. Create the user
# 2. Request password
# 3. Create home directory
# 4. Request optional information (full name, etc)

# Add to sudo group (optional)
usermod -aG sudo john

# Configure Xfce4 session
echo "startxfce4" > /home/john/.xsession
```

**Method 2: Using `useradd` (Non-interactive)**

```bash
# Enter the container
make exec SVC=deskbox CTX=hostname

# Create the user
useradd -m -s /bin/bash mary

# Set the password
passwd mary

# Add to sudo group (optional)
usermod -aG sudo mary

# Configure Xfce4 session
echo "startxfce4" > /home/mary/.xsession
```

### Connecting with Different Users

Each user can connect simultaneously via RDP:

```bash
# User 1: deskbox
rdesktop -u deskbox -p deskbox_password hostname:3389

# User 2: john (in another session)
rdesktop -u john -p john_password hostname:3389

# User 3: mary (in another session)
rdesktop -u mary -p mary_password hostname:3389
```

### Multiple Users Features

**Each user has:**
- Separate and persistent home directory
- Independent Xfce4 session
- Own configurations
- Sudo permissions (by default)

**Support for:**
- Multiple simultaneous sessions
- Data persisted in `/mnt/deskbox/home` volume
- Standard structure (Desktop, Documents, etc)

### Managing Users

Enter the container and use standard Debian commands:

```bash
make exec SVC=deskbox CTX=hostname
```

**List users:**
```bash
cat /etc/passwd | grep /home
# or
cut -d: -f1 /etc/passwd
```

**Remove user:**
```bash
deluser --remove-home john  # Debian command
# or
userdel -r john             # Traditional Linux command
```

**Change password:**
```bash
passwd john
```

**View user information:**
```bash
id john
groups john
```

## Security Considerations

### ✅ Security Improvements Implemented

This project includes enhanced security features:

1. **✅ Sudo with Password**: NOPASSWD has been removed - sudo now requires password
2. **✅ Docker Secrets Support**: Secure password management via Docker secrets
3. **✅ Log Rotation**: Automatic log rotation to prevent disk space issues
4. **✅ Script Validations**: Enhanced input validation and error handling

### Security Options

#### Standard Configuration (Development)
```bash
# Use environment variables in .env
make start CTX=hostname
```

#### Production Configuration (Recommended)
```bash
# Set secure password in .env file
echo "USER_PASSWORD=your_secure_password" >> .env
make start CTX=hostname
```

#### Option 2: Production Configuration (Recommended)
```bash
# Use docker-compose.prod.yml with Docker secrets
./scripts/manage-secrets.sh user-password your_secure_password
DOCKER_COMPOSE_FILE=docker-compose.prod.yml make start CTX=hostname
```

#### Option 3: High Security Configuration
```bash
# Use docker-compose.secure.yml with restricted access
./scripts/manage-secrets.sh user-password your_secure_password
DOCKER_COMPOSE_FILE=docker-compose.secure.yml make start CTX=hostname

# Access via SSH tunnel
./scripts/secure-rdp.sh hostname 3389 deskbox
```

### Important Security Notes

1. **Password Management**
   - **Development**: Environment variables (`.env` file)
   - **Production**: Docker secrets (recommended)
   - **Never commit passwords to Git**

2. **Network Access**
   - **Standard**: RDP exposed on `0.0.0.0:3389`
   - **Secure**: RDP on `127.0.0.1:3389` (localhost only)
   - **SSH Tunnel**: Most secure option for remote access

3. **Container Security**
   - **User isolation**: Non-root user with limited privileges
   - **Filesystem**: Read-only with specific writable directories
   - **Capabilities**: Minimal Linux capabilities
   - **Resource limits**: CPU and memory constraints

4. **Chromium Browser**
   - Runs with `--no-sandbox` (required for containers)
   - **Safe**: Docker provides container-level isolation
   - **Standard approach** for browsers in containers

### Security Best Practices

#### For Production Environments:

1. **Use Environment Variables**:
   ```bash
   echo "USER_PASSWORD=your_secure_password" >> .env
   # Store the password securely
   ```

2. **Monitor Logs**:
   ```bash
   make view-logs CTX=hostname
   ./scripts/log-rotation.sh stats
   ```

3. **Regular Updates**:
   ```bash
   # Update base image regularly
   make build CTX=hostname
   make start CTX=hostname
   ```

### Security Monitoring

The project includes automated security monitoring:

- **Log Rotation**: Prevents disk space exhaustion
- **Health Checks**: Monitors service availability
- **Access Logging**: Tracks connection attempts
- **Resource Limits**: Prevents resource exhaustion attacks

## Volume Structure

```
/mnt/deskbox/
    ├── home/                    → /home (in container)
    │   ├── deskbox/              # Default user (UID 1000)
    │   │   ├── Desktop/
    │   │   ├── Documents/
    │   │   ├── Downloads/
    │   │   ├── Pictures/
    │   │   └── Videos/
    │   ├── john/                # Additional users
    │   ├── mary/
    │   └── ...
    │
    └── logs/                    → /var/log/deskbox (in container)
        ├── startup.log          # Deskbox startup logs
        └── xrdp.log             # XRDP server logs
```

**Persisted data on the host:**
- **Home directories**: `/mnt/deskbox/home/*` - All user data, configurations, and files
- **Logs**: `/mnt/deskbox/logs/*` - Startup and XRDP logs for troubleshooting

## Pre-installed Tools

Debian-RDP comes with essential development and system tools pre-installed:

**Development Tools:**
- git - Version control
- vim - Text editor
- tmux - Terminal multiplexer
- tree - Directory visualization

**System Monitoring:**
- htop - Interactive process viewer
- net-tools - Network utilities
- iputils-ping - Network diagnostics

**Desktop Applications:**
- Chromium - Web browser (optimized for containers)
- Chromium Simple - Web browser without keyring password prompts
- Thunar - File manager
- Mousepad - Text editor
- Xfce4 Terminal - Terminal emulator
- Task Manager - System monitor
- Screenshot Tool - Screen capture

**Custom Aliases (available in terminal):**
```bash
ll          # Detailed file listing (ls -lah)
gs          # Git status
gp          # Git pull
gc          # Git commit
gd          # Git diff
update      # System update (apt update && upgrade)
ports       # Show network ports (netstat)
chromium    # Opens Chromium Simple (no keyring prompts)
chrome       # Opens Chromium Simple (no keyring prompts)
```

## Keyring Configuration

The container comes with pre-configured keyring settings to prevent password prompts:

### ✅ Automatic Configuration
- **Empty keyring** created during build
- **Chromium Simple** wrapper without keyring prompts
- **Environment variables** set to disable keyring
- **Aliases** configured for easy access

### 🌐 Browser Options
1. **Chromium Simple**: Use `chromium` or `chromium-simple` command
2. **Standard Chromium**: Still available if needed (may prompt for keyring)

### 🔧 Manual Configuration (if needed)
If you need to reconfigure keyring settings:
```bash
# Inside container as deskbox user
mkdir -p ~/.local/share/keyrings
cat > ~/.local/share/keyrings/default << 'EOF'
[keyring]
display-name=Default
lock-on-idle=false
lock-timeout=0
EOF
```

## Logging and Monitoring

Debian-RDP implements structured logging for better troubleshooting:

**View startup logs:**
```bash
make view-logs CTX=hostname
```

**Monitor active sessions:**
```bash
make sessions CTX=hostname
```

**View real-time Docker logs:**
```bash
make logs CTX=hostname
```

**Log files (persisted on host at `/mnt/deskbox/logs/`):**
- `startup.log` - Startup process logs
- `xrdp.log` - XRDP server logs

**Note**: Logs are persisted on the host, so they survive container restarts and rebuilds.

## Backup and Restore

**Create backup:**
```bash
make backup CTX=hostname
```

This creates a timestamped backup file in `/tmp/deskbox-backup-YYYYMMDD-HHMMSS.tar.gz` on the remote host.

The backup includes:
- All user home directories (`/mnt/deskbox/home/*`)
- All logs (`/mnt/deskbox/logs/*`)

**Restore from backup:**
```bash
# On the remote host
ssh root@hostname
cd /tmp
tar -xzf deskbox-backup-20250113-120000.tar.gz -C /
```

**Manual backup of specific directories:**
```bash
# Backup only home directories
ssh root@hostname "tar -czf /tmp/deskbox-home-backup.tar.gz /mnt/deskbox/home"

# Backup only logs
ssh root@hostname "tar -czf /tmp/deskbox-logs-backup.tar.gz /mnt/deskbox/logs"
```

## Troubleshooting

### Cannot connect via RDP

1. Check if the container is running:
   ```bash
   make ps CTX=hostname
   ```

2. Check the container health:
   ```bash
   docker ps  # Look for "healthy" status
   ```

3. Check the logs:
   ```bash
   make logs CTX=hostname
   # Or view Debian-RDP-specific logs
   make view-logs CTX=hostname
   ```

4. Test connectivity:
   ```bash
   telnet hostname 3389
   ```

### Cannot connect via SSH

1. Verify SSH port is exposed:
   ```bash
   docker ps | grep deskbox
   # Should show 0.0.0.0:2222->22/tcp
   ```

2. Test SSH connectivity:
   ```bash
   telnet hostname 2222
   ```

3. Try connecting with verbose mode:
   ```bash
   ssh -v -p 2222 deskbox@hostname
   ```

### Black screen after login

1. Check Debian-RDP logs for errors:
   ```bash
   make view-logs CTX=hostname
   ```

2. Check home directory permissions:
   ```bash
   make exec SVC=deskbox CTX=hostname
   ls -la /home/deskbox
   ```

3. Verify XFCE4 configuration:
   ```bash
   make exec SVC=deskbox CTX=hostname
   cat /home/deskbox/.xsession
   # Should contain: startxfce4
   ```

4. Restart the container:
   ```bash
   make restart CTX=hostname
   ```

### "USER_PASSWORD not defined"

Verify that the `.env` file exists and contains:
```bash
USER_PASSWORD=your_password
```

## Environment Variables

All environment variables should be configured in the `.env` file (copy from `.env.example`):

| Variable | Default | Description |
|----------|--------|-----------|
| `DOCKER_USER` | carlosrabelo | Docker Hub username |
| `IMAGE_NAME` | deskbox | Docker image name |
| `USER_PASSWORD` | deskbox | RDP password (change this!) |
| `TZ` | America/Cuiaba | System timezone |

## Architecture

```
┌─────────────────────────────────────┐
│  RDP Client (Remmina/mstsc)         │
│  SSH Client (Terminal)              │
└──────────┬──────────────┬───────────┘
           │ Port 3389    │ Port 2222
           │ (RDP)        │ (SSH)
┌──────────▼──────────────▼───────────┐
│         Docker Container            │
│  ┌───────────────────────────────┐  │
│  │         XRDP Server           │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │      XRDP Session Manager     │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │      Xorg (xorgxrdp)          │  │
│  └──────────────┬────────────────┘  │
│  ┌──────────────▼────────────────┐  │
│  │     Xfce4 Desktop             │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │         SSH Server            │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## License

MIT License - Use at your own risk.

## Contributing

PRs are welcome! For major changes, please open an issue first.

## Support

For issues or questions, please open an issue in the repository.
