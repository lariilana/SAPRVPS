#!/bin/bash

# Sa Plays Roblox Streamer - Automated Installation Script (Replit Version)
# This script automatically installs and configures the complete streaming application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Sa Plays Roblox Streamer"
APP_DIR="/opt/sa-plays-streamer"
DB_NAME="streaming_db"
DB_USER="streaming_user"
DB_PASS=""
SERVICE_NAME="sa-plays-streamer"
APP_PORT="5000"
RTMP_PORT="1935"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_status "Detected OS: $OS $VERSION"
}

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to install system dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            sudo apt update
            sudo apt install -y curl wget gnupg2 software-properties-common
            
            # Node.js 20
            print_status "Installing Node.js 20..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            
            # PostgreSQL
            print_status "Installing PostgreSQL..."
            sudo apt install -y postgresql postgresql-contrib
            
            # FFmpeg
            print_status "Installing FFmpeg..."
            sudo apt install -y ffmpeg
            
            # Nginx with RTMP
            print_status "Installing Nginx with RTMP module..."
            sudo apt install -y nginx libnginx-mod-rtmp
            
            # Additional tools
            sudo apt install -y git unzip htop ufw
            ;;
            
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            sudo yum update -y
            sudo yum install -y curl wget epel-release
            
            # Node.js 20
            print_status "Installing Node.js 20..."
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo yum install -y nodejs
            
            # PostgreSQL
            print_status "Installing PostgreSQL..."
            sudo yum install -y postgresql-server postgresql-contrib
            sudo postgresql-setup initdb
            
            # FFmpeg
            print_status "Installing FFmpeg..."
            sudo yum install -y ffmpeg
            
            # Nginx
            print_status "Installing Nginx..."
            sudo yum install -y nginx
            
            # Additional tools
            sudo yum install -y git unzip htop firewalld
            ;;
            
        *)
            print_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    print_success "System dependencies installed successfully"
}

# Function to start services
start_services() {
    print_status "Starting and enabling services..."
    
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    print_success "Services started and enabled"
}

# Function to setup database
setup_database() {
    print_status "Setting up PostgreSQL database..."
    
    # Generate secure password
    DB_PASS=$(generate_password)
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF
    
    print_success "Database '$DB_NAME' and user '$DB_USER' created"
    print_status "Database password: $DB_PASS"
}

# Function to download and extract application
setup_application() {
    print_status "Setting up application directory..."
    
    # Create application directory
    sudo mkdir -p $APP_DIR
    sudo chown $USER:$USER $APP_DIR
    
    echo
    print_warning "APPLICATION PACKAGE REQUIRED"
    echo "Please ensure you have one of these files in the current directory:"
    echo "  - sa-plays-streamer-complete.tar.gz (recommended - includes all dependencies)"
    echo "  - sa-plays-streamer-source-only.tar.gz (requires npm install)"
    echo
    read -p "Press Enter when you have the package file ready..."
    
    # Check for package files
    if [[ -f "sa-plays-streamer-complete.tar.gz" ]]; then
        print_status "Found complete package, extracting..."
        tar -xzf sa-plays-streamer-complete.tar.gz -C $APP_DIR --strip-components=1
        PACKAGE_TYPE="complete"
    elif [[ -f "sa-plays-streamer-source-only.tar.gz" ]]; then
        print_status "Found source-only package, extracting..."
        tar -xzf sa-plays-streamer-source-only.tar.gz -C $APP_DIR --strip-components=1
        PACKAGE_TYPE="source"
    else
        print_error "No package file found. Please download one of the packages first."
        exit 1
    fi
    
    cd $APP_DIR
    
    # Install dependencies if needed
    if [[ "$PACKAGE_TYPE" == "source" ]]; then
        print_status "Installing Node.js dependencies..."
        npm ci
    fi
    
    print_success "Application extracted and dependencies installed"
}

# Function to configure environment
configure_environment() {
    print_status "Configuring environment variables..."
    
    cd $APP_DIR
    
    # Create production environment file
    cat > .env.production << EOF
# Sa Plays Roblox Streamer - Production Configuration
NODE_ENV=production
PORT=$APP_PORT

# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME
PGHOST=localhost
PGPORT=5432
PGUSER=$DB_USER
PGPASSWORD=$DB_PASS
PGDATABASE=$DB_NAME

# Application Settings
RTMP_PORT=$RTMP_PORT
WEB_PORT=$APP_PORT

# Security (generate new values for production)
SESSION_SECRET=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

# Optional: Add your streaming platform API keys here
# YOUTUBE_API_KEY=your_youtube_api_key
# TWITCH_CLIENT_ID=your_twitch_client_id
# FACEBOOK_APP_ID=your_facebook_app_id
EOF
    
    # Set proper permissions
    chmod 600 .env.production
    
    print_success "Environment configuration created"
}

# Function to initialize database schema
initialize_database() {
    print_status "Initializing database schema..."
    
    cd $APP_DIR
    export $(cat .env.production | xargs)
    
    # Initialize database schema
    npm run db:push
    
    print_success "Database schema initialized"
}

# Function to build application
build_application() {
    print_status "Building application..."
    
    cd $APP_DIR
    export $(cat .env.production | xargs)
    
    # Build frontend and backend
    npm run build
    
    # Verify build
    if [[ -d "dist" && -f "dist/index.js" ]]; then
        print_success "Application built successfully"
    else
        print_error "Build failed - dist directory or index.js not found"
        exit 1
    fi
}

# Function to create systemd service
create_service() {
    print_status "Creating systemd service..."
    
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=$APP_NAME
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
EnvironmentFile=$APP_DIR/.env.production
ExecStart=/usr/bin/npm run start
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$APP_DIR $APP_DIR/uploads $APP_DIR/backups
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF
    
    print_success "Systemd service created"
}

# Function to configure nginx
configure_nginx() {
    print_status "Configuring Nginx..."
    
    # Copy nginx configuration
    if [[ -f "$APP_DIR/nginx-standalone.conf" ]]; then
        sudo cp $APP_DIR/nginx-standalone.conf /etc/nginx/sites-available/$SERVICE_NAME
        
        # Enable site
        sudo ln -sf /etc/nginx/sites-available/$SERVICE_NAME /etc/nginx/sites-enabled/
        
        # Remove default site
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Test configuration
        sudo nginx -t
        
        print_success "Nginx configured successfully"
    else
        print_warning "Nginx configuration file not found, using default setup"
    fi
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            sudo ufw --force enable
            sudo ufw allow $APP_PORT/tcp comment "Sa Plays Streamer Web"
            sudo ufw allow $RTMP_PORT/tcp comment "Sa Plays Streamer RTMP"
            sudo ufw allow 80/tcp comment "HTTP"
            sudo ufw allow 443/tcp comment "HTTPS"
            sudo ufw allow 22/tcp comment "SSH"
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            sudo systemctl start firewalld
            sudo systemctl enable firewalld
            sudo firewall-cmd --permanent --add-port=$APP_PORT/tcp
            sudo firewall-cmd --permanent --add-port=$RTMP_PORT/tcp
            sudo firewall-cmd --permanent --add-service=http
            sudo firewall-cmd --permanent --add-service=https
            sudo firewall-cmd --permanent --add-service=ssh
            sudo firewall-cmd --reload
            ;;
    esac
    
    print_success "Firewall configured"
}

# Function to start application
start_application() {
    print_status "Starting application services..."
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable and start application
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
    
    # Restart nginx
    sudo systemctl restart nginx
    
    # Wait a moment for startup
    sleep 5
    
    # Check service status
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        print_success "Application started successfully"
    else
        print_error "Application failed to start"
        print_status "Checking logs..."
        sudo journalctl -u $SERVICE_NAME --no-pager -n 20
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Test database connection
    if curl -s http://localhost:$APP_PORT/api/system-config > /dev/null; then
        print_success "API endpoints responding"
    else
        print_warning "API not responding, checking service status..."
        sudo systemctl status $SERVICE_NAME --no-pager -l
    fi
    
    # Test FFmpeg
    if curl -s http://localhost:$APP_PORT/api/stream-status > /dev/null; then
        print_success "Streaming endpoints responding"
    else
        print_warning "Streaming endpoints not responding"
    fi
}

# Function to display completion info
display_completion() {
    echo
    echo "=========================================="
    print_success "$APP_NAME Installation Complete!"
    echo "=========================================="
    echo
    echo "🌐 Web Interface: http://$(hostname -I | awk '{print $1}'):$APP_PORT"
    echo "🔐 Database: $DB_NAME (user: $DB_USER)"
    echo "📁 Application Directory: $APP_DIR"
    echo "⚙️  Service Name: $SERVICE_NAME"
    echo
    echo "Management Commands:"
    echo "  Start:   sudo systemctl start $SERVICE_NAME"
    echo "  Stop:    sudo systemctl stop $SERVICE_NAME"
    echo "  Restart: sudo systemctl restart $SERVICE_NAME"
    echo "  Status:  sudo systemctl status $SERVICE_NAME"
    echo "  Logs:    sudo journalctl -u $SERVICE_NAME -f"
    echo
    echo "Configuration Files:"
    echo "  Environment: $APP_DIR/.env.production"
    echo "  Nginx:       /etc/nginx/sites-available/$SERVICE_NAME"
    echo "  Service:     /etc/systemd/system/$SERVICE_NAME.service"
    echo
    print_warning "IMPORTANT: Save this database password: $DB_PASS"
    echo
    echo "🎥 Your streaming application is ready!"
    echo "   Upload videos, configure streaming platforms, and start broadcasting!"
    echo
}

# Main installation function
main() {
    echo "=========================================="
    echo "🎮 $APP_NAME - Automated Installer"
    echo "=========================================="
    echo
    
    check_root
    detect_os
    
    print_status "This script will install:"
    echo "  ✓ Node.js 20, PostgreSQL, FFmpeg, Nginx"
    echo "  ✓ $APP_NAME application"
    echo "  ✓ Database setup with secure credentials"
    echo "  ✓ Systemd service configuration"
    echo "  ✓ Firewall configuration"
    echo "  ✓ Complete streaming setup"
    echo
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    echo
    print_status "Starting installation..."
    
    install_dependencies
    start_services
    setup_database
    setup_application
    configure_environment
    initialize_database
    build_application
    create_service
    configure_nginx
    configure_firewall
    start_application
    verify_installation
    display_completion
}

# Run main function
main "$@"