# Sa Plays Roblox Streamer - Quick Install Guide

## 🚀 One-Command Installation

This automated script installs your complete Sa Plays Roblox Streamer application with all dependencies, database setup, and system configuration.

### Prerequisites
- **Ubuntu 20.04+** / **Debian 11+** / **CentOS 8+** / **Rocky Linux 8+**
- **Root/sudo access**
- **2GB+ RAM** (4GB+ recommended)
- **10GB+ free disk space**
- **Stable internet connection**

### Quick Installation

1. **Download your application package** to the server:
   - `sa-plays-streamer-complete.tar.gz` (recommended - 173MB)
   - OR `sa-plays-streamer-source-only.tar.gz` (5.8MB)

2. **Download the install script**:
   ```bash
   wget https://your-replit-url/install-sa-plays-replit.sh
   # OR if downloaded from Replit, upload both files to your server
   ```

3. **Run the installer**:
   ```bash
   chmod +x install-sa-plays-replit.sh
   ./install-sa-plays-replit.sh
   ```

4. **Access your application**:
   - Open browser: `http://your-server-ip:5000`
   - Start streaming! 🎥

## What the Script Does

### ✅ **System Setup**
- Installs Node.js 20, PostgreSQL, FFmpeg, Nginx
- Configures system services and firewall
- Sets up user permissions and security

### ✅ **Database Configuration**
- Creates PostgreSQL database and user
- Generates secure random password
- Initializes application schema
- Tests database connectivity

### ✅ **Application Deployment**
- Extracts your application package
- Installs all Node.js dependencies
- Builds frontend and backend
- Configures environment variables

### ✅ **Service Management**
- Creates systemd service for auto-start
- Configures Nginx for RTMP streaming
- Sets up proper logging and monitoring
- Enables automatic restarts

### ✅ **Security & Firewall**
- Opens required ports (5000, 1935, 80, 443)
- Configures secure file permissions
- Generates random security keys
- Enables system firewall

## Installation Output

The script provides real-time status updates:

```
🎮 Sa Plays Roblox Streamer - Automated Installer
==============================================

[INFO] Detected OS: Ubuntu 22.04
[INFO] Installing system dependencies...
[SUCCESS] System dependencies installed successfully
[INFO] Setting up PostgreSQL database...
[SUCCESS] Database 'streaming_db' and user 'streaming_user' created
[INFO] Building application...
[SUCCESS] Application built successfully
[INFO] Starting application services...
[SUCCESS] Application started successfully

🌐 Web Interface: http://192.168.1.100:5000
🔐 Database: streaming_db (user: streaming_user)
📁 Application Directory: /opt/sa-plays-streamer
```

## Post-Installation

### Access Your Application
- **Web Dashboard**: `http://your-server-ip:5000`
- **Default Login**: No login required (configure in settings)

### Manage the Service
```bash
# Check status
sudo systemctl status sa-plays-streamer

# View logs
sudo journalctl -u sa-plays-streamer -f

# Restart service
sudo systemctl restart sa-plays-streamer

# Stop service
sudo systemctl stop sa-plays-streamer
```

### Add Streaming Platform Keys
1. Open web interface
2. Go to **Settings** → **Platform Settings**
3. Add your YouTube/Twitch/Facebook stream keys
4. Configure video quality and bitrate
5. Start streaming!

## Troubleshooting

### Installation Failed?
```bash
# Check script logs
./install-sa-plays-replit.sh 2>&1 | tee install.log

# Check system logs
sudo journalctl -xe

# Verify dependencies
node --version    # Should show v20.x.x
ffmpeg -version   # Should show FFmpeg info
sudo -u postgres psql -c "SELECT version();"  # Test PostgreSQL
```

### Application Won't Start?
```bash
# Check service status
sudo systemctl status sa-plays-streamer

# View detailed logs
sudo journalctl -u sa-plays-streamer -n 50

# Test database connection
cd /opt/sa-plays-streamer
npm run db:push
```

### Can't Access Web Interface?
```bash
# Check if service is running
curl http://localhost:5000/api/system-config

# Check firewall
sudo ufw status
sudo netstat -tlnp | grep :5000

# Check nginx status
sudo systemctl status nginx
sudo nginx -t
```

## Manual Uninstall

If you need to remove the installation:

```bash
# Stop services
sudo systemctl stop sa-plays-streamer nginx

# Remove application
sudo rm -rf /opt/sa-plays-streamer

# Remove service
sudo rm /etc/systemd/system/sa-plays-streamer.service
sudo systemctl daemon-reload

# Remove database (optional)
sudo -u postgres dropdb streaming_db
sudo -u postgres dropuser streaming_user

# Remove nginx config
sudo rm /etc/nginx/sites-enabled/sa-plays-streamer
sudo rm /etc/nginx/sites-available/sa-plays-streamer
```

## Features Ready After Installation

✅ **Video Management**: Upload, organize, and manage video playlists  
✅ **Multi-Platform Streaming**: YouTube, Twitch, Facebook support  
✅ **24/7 Loop Mode**: Continuous playlist broadcasting  
✅ **Real-Time Dashboard**: Live stream status and viewer metrics  
✅ **FFmpeg Integration**: Professional video encoding and streaming  
✅ **RTMP Support**: Local RTMP server for advanced workflows  
✅ **System Management**: Database backup/restore, configuration  

## Support

The installation script is designed to be bulletproof and handle most common scenarios. If you encounter issues:

1. **Check the logs** with the commands above
2. **Verify all prerequisites** are met
3. **Ensure package files** are in the same directory as the script
4. **Check internet connectivity** for dependency downloads

Your Sa Plays Roblox Streamer is now ready for professional streaming! 🎮📺