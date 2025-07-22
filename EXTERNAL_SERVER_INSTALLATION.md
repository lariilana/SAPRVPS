# Sa Plays Roblox Streamer - External Server Installation Guide

## Prerequisites

### System Requirements
- **Operating System**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+ / macOS
- **RAM**: Minimum 2GB, Recommended 4GB+
- **Storage**: 10GB+ free space
- **Network**: Stable internet connection for streaming

### Required Software Installation

#### 1. Node.js 20+ Installation
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x
```

#### 2. PostgreSQL Database
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE streaming_db;
CREATE USER streaming_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE streaming_db TO streaming_user;
\q
```

#### 3. FFmpeg for Video Processing
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install epel-release
sudo yum install ffmpeg

# Verify FFmpeg installation
ffmpeg -version
```

#### 4. Nginx with RTMP Module (Optional but Recommended)
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx libnginx-mod-rtmp

# CentOS/RHEL
sudo yum install nginx nginx-mod-rtmp

# Enable and start nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Installation Steps

### Step 1: Download and Extract Application
```bash
# Create application directory
sudo mkdir -p /opt/sa-plays-streamer
cd /opt/sa-plays-streamer

# Download the complete package (replace with your download method)
# Option A: If you downloaded sa-plays-streamer-complete.tar.gz
tar -xzf sa-plays-streamer-complete.tar.gz

# Option B: If you downloaded sa-plays-streamer-source-only.tar.gz
tar -xzf sa-plays-streamer-source-only.tar.gz
npm ci  # Install dependencies from package-lock.json

# Set ownership
sudo chown -R $USER:$USER /opt/sa-plays-streamer
```

### Step 2: Environment Configuration
```bash
# Create production environment file
cd /opt/sa-plays-streamer
cp .env.example .env.production

# Edit environment variables
nano .env.production
```

**Required Environment Variables:**
```bash
# Database Configuration
DATABASE_URL=postgresql://streaming_user:your_secure_password@localhost:5432/streaming_db

# Application Settings
NODE_ENV=production
PORT=5000

# Optional: External Database (if using remote PostgreSQL)
PGHOST=localhost
PGPORT=5432
PGUSER=streaming_user
PGPASSWORD=your_secure_password
PGDATABASE=streaming_db

# Optional: Streaming Platform Keys (add as needed)
# YOUTUBE_API_KEY=your_youtube_api_key
# TWITCH_CLIENT_ID=your_twitch_client_id
```

### Step 3: Database Schema Setup
```bash
cd /opt/sa-plays-streamer

# Initialize database schema
npm run db:push

# Verify database connection
node -e "
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
pool.query('SELECT NOW()', (err, res) => {
  if (err) console.error('Database connection failed:', err);
  else console.log('Database connected successfully:', res.rows[0]);
  pool.end();
});
"
```

### Step 4: Build Application
```bash
cd /opt/sa-plays-streamer

# Build frontend and backend
npm run build

# Verify build completed
ls -la dist/
# Should show: public/ (frontend) and index.js (backend)
```

### Step 5: Create System Service
```bash
# Create systemd service file
sudo nano /etc/systemd/system/sa-plays-streamer.service
```

**Service Configuration:**
```ini
[Unit]
Description=Sa Plays Roblox Streamer
After=network.target postgresql.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/opt/sa-plays-streamer
Environment=NODE_ENV=production
Environment=DATABASE_URL=postgresql://streaming_user:your_secure_password@localhost:5432/streaming_db
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=sa-plays-streamer

[Install]
WantedBy=multi-user.target
```

### Step 6: Configure Nginx (Optional RTMP Support)
```bash
# Backup original nginx config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Copy application nginx config
sudo cp nginx-standalone.conf /etc/nginx/sites-available/sa-plays-streamer

# Enable the site
sudo ln -s /etc/nginx/sites-available/sa-plays-streamer /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### Step 7: Start Application Services
```bash
# Reload systemd and start application
sudo systemctl daemon-reload
sudo systemctl enable sa-plays-streamer
sudo systemctl start sa-plays-streamer

# Check service status
sudo systemctl status sa-plays-streamer

# View application logs
sudo journalctl -u sa-plays-streamer -f
```

### Step 8: Configure Firewall
```bash
# Open required ports
sudo ufw allow 5000/tcp   # Application port
sudo ufw allow 1935/tcp   # RTMP port (if using nginx RTMP)
sudo ufw allow 8080/tcp   # HLS port (if using nginx)
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS (if using SSL)

# Enable firewall
sudo ufw enable
```

## Verification Steps

### Test Application
```bash
# Check if application is running
curl http://localhost:5000/api/system-config

# Expected response: JSON with system configuration

# Test FFmpeg availability
curl http://localhost:5000/api/test-ffmpeg

# Expected response: FFmpeg version information
```

### Test Database Connection
```bash
curl http://localhost:5000/api/stream-status

# Expected response: Stream status JSON
```

### Access Web Interface
Open browser and navigate to: `http://your-server-ip:5000`

## Optional: SSL/HTTPS Setup
```bash
# Install certbot for Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate (replace your-domain.com)
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Troubleshooting

### Common Issues

**1. Application won't start**
```bash
# Check logs
sudo journalctl -u sa-plays-streamer -n 50

# Check if port is available
sudo netstat -tlnp | grep :5000
```

**2. Database connection fails**
```bash
# Test PostgreSQL connection
sudo -u postgres psql -c "SELECT version();"

# Check if database exists
sudo -u postgres psql -l | grep streaming_db
```

**3. FFmpeg not found**
```bash
# Verify FFmpeg installation
which ffmpeg
ffmpeg -version

# Reinstall if needed
sudo apt install --reinstall ffmpeg
```

**4. RTMP streaming issues**
```bash
# Check nginx RTMP module
nginx -V 2>&1 | grep -o with-http_realip_module

# Test RTMP endpoint
ffmpeg -re -i test.mp4 -c copy -f flv rtmp://localhost:1935/live/test
```

## Performance Optimization

### For Production Use
```bash
# Increase file limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize PostgreSQL
sudo nano /etc/postgresql/*/main/postgresql.conf
# Adjust: shared_buffers, effective_cache_size, work_mem

# Enable nginx compression
sudo nano /etc/nginx/nginx.conf
# Add: gzip on; gzip_types text/css application/javascript;
```

## Maintenance Commands

```bash
# Start/stop application
sudo systemctl start sa-plays-streamer
sudo systemctl stop sa-plays-streamer
sudo systemctl restart sa-plays-streamer

# View logs
sudo journalctl -u sa-plays-streamer -f

# Update application
cd /opt/sa-plays-streamer
git pull  # if using git
npm ci
npm run build
sudo systemctl restart sa-plays-streamer

# Database backup
pg_dump -U streaming_user -h localhost streaming_db > backup_$(date +%Y%m%d).sql
```

## Special Software Requirements

**No special Replit software is needed!** The application has been migrated to use standard technologies:

- ✅ **Node.js 20**: Standard runtime (no Replit-specific versions)
- ✅ **PostgreSQL**: Standard database (any PostgreSQL 12+ works)
- ✅ **FFmpeg**: Standard video processing (system package)
- ✅ **Nginx**: Standard web server (optional, for RTMP)

**What was removed from Replit dependencies:**
- tsx (TypeScript runner) → replaced with compiled JavaScript
- Replit-specific database connections → standard PostgreSQL
- Replit deployment tools → standard systemd service

Your app is now fully portable and doesn't require any Replit-specific infrastructure!