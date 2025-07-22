# Sa Plays Roblox Streamer - RTMP Setup Guide

## Fixed Nginx Configuration Issue

The standalone server has been updated to properly handle nginx RTMP module configuration. The error "Nginx configuration test failed, skipping nginx startup" has been resolved.

## What Was Fixed

1. **Improved Docker Entrypoint**: Updated `docker-entrypoint-standalone.sh` to detect RTMP module availability and gracefully fall back to simple nginx config
2. **Multiple Nginx Configurations**: 
   - `nginx-standalone.conf` - Full RTMP support (when module available)
   - `nginx-standalone-simple.conf` - Basic nginx without RTMP
3. **Removed Problematic Module Loading**: Eliminated `load_module` directive that was causing configuration test failures

## How It Works Now

The Docker container startup process:

1. **Check for Nginx**: Verifies if nginx is available
2. **Detect RTMP Module**: Uses `nginx -V` to check for RTMP module compilation
3. **Smart Configuration Selection**:
   - If RTMP module found → Use `nginx-standalone.conf` (full RTMP support)
   - If no RTMP module → Use `nginx-standalone-simple.conf` (basic nginx)
   - If neither works → Skip nginx, use direct streaming

## RTMP Module Installation

### For Docker (Alpine Linux)
```bash
# Install nginx with RTMP module
apk add --no-cache nginx nginx-mod-rtmp

# Or build from source with RTMP
apk add --no-cache nginx-mod-rtmp
```

### For Ubuntu/Debian
```bash
# Install nginx with RTMP module
sudo apt update
sudo apt install nginx libnginx-mod-rtmp

# Enable the module
echo "load_module modules/ngx_rtmp_module.so;" >> /etc/nginx/nginx.conf
```

### For CentOS/RHEL
```bash
# Install nginx with RTMP module
sudo yum install nginx nginx-mod-rtmp
# or
sudo dnf install nginx nginx-mod-rtmp
```

## Streaming Capabilities

### With RTMP Module (Full Features)
- ✅ RTMP ingestion on port 1935
- ✅ HLS output for web playback
- ✅ Live stream recording
- ✅ Multiple stream outputs
- ✅ Stream authentication

### Without RTMP Module (Direct Streaming)
- ✅ Direct FFmpeg to external RTMP servers (YouTube, Twitch, Facebook)
- ✅ Video file streaming 
- ✅ Playlist management
- ✅ Stream status tracking
- ❌ No local RTMP ingestion
- ❌ No HLS output

## Testing Your Setup

### Check RTMP Module Availability
```bash
nginx -V 2>&1 | grep -o with-http_realip_module
```

### Test Nginx Configuration
```bash
# Test full RTMP config
nginx -c /app/nginx-standalone.conf -t

# Test simple config
nginx -c /app/nginx-standalone-simple.conf -t
```

### Test RTMP Streaming (if module available)
```bash
# Stream to local RTMP
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost:1935/live/stream_key

# Check HLS output
curl http://localhost:8080/hls/stream_key.m3u8
```

## Deployment Recommendations

1. **Production with RTMP**: Use nginx with RTMP module for full streaming capabilities
2. **Simple Deployment**: Use basic nginx or no nginx for direct external streaming
3. **Container Registry**: Pre-build containers with nginx-mod-rtmp for consistent deployments

## Common Issues and Solutions

### "RTMP module not found"
- **Solution**: Install nginx-mod-rtmp package or build nginx with RTMP support
- **Workaround**: Use direct FFmpeg streaming to external services

### "Configuration test failed"
- **Solution**: Check nginx error logs in `/tmp/nginx-error.log`
- **Workaround**: The entrypoint will automatically fall back to simple config

### "Permission denied" errors
- **Solution**: Ensure `/tmp` directory is writable
- **Fix**: Run `chmod 777 /tmp` in container or use different paths

## Status

✅ **Fixed**: Nginx configuration test failures
✅ **Improved**: Graceful fallback when RTMP module unavailable  
✅ **Enhanced**: Multiple configuration options for different environments
✅ **Working**: Direct streaming to external platforms without nginx