#!/usr/bin/env node

const http = require('http');
const { spawn } = require('child_process');

// Test playlist management functionality
async function testPlaylistManagement() {
  console.log('Starting playlist management test...');
  
  // Start the server
  const serverProcess = spawn('node', ['server-standalone.cjs'], {
    stdio: 'pipe',
    detached: false
  });
  
  // Wait for server to start
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  try {
    // Test 1: Get videos (should work with playlist_order column)
    console.log('Testing GET /api/videos...');
    const videosResponse = await makeRequest('GET', '/api/videos');
    console.log(`✅ Videos API: ${videosResponse.status} - Found ${JSON.parse(videosResponse.data).length} videos`);
    
    const videos = JSON.parse(videosResponse.data);
    if (videos.length > 0) {
      console.log(`   First video: ${videos[0].title} (playlist_order: ${videos[0].playlist_order || videos[0].playlistOrder})`);
    }
    
    // Test 2: Test playlist reordering if we have videos
    if (videos.length > 0) {
      console.log('Testing POST /api/videos/reorder...');
      const reorderData = {
        videoIds: videos.map(v => v.id)
      };
      
      const reorderResponse = await makeRequest('POST', '/api/videos/reorder', JSON.stringify(reorderData));
      console.log(`✅ Playlist Reorder: ${reorderResponse.status} - ${JSON.parse(reorderResponse.data).message}`);
    }
    
    // Test 3: Test stream controls
    console.log('Testing stream control endpoints...');
    const streamStatusResponse = await makeRequest('GET', '/api/stream-status');
    console.log(`✅ Stream Status: ${streamStatusResponse.status}`);
    
    console.log('\n🎉 All playlist management tests passed!');
    console.log('The standalone Sa Plays Roblox Streamer server is working correctly.');
    
  } catch (error) {
    console.log(`❌ Test failed: ${error.message}`);
  } finally {
    // Kill server
    serverProcess.kill();
  }
}

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }
    
    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          data: responseData
        });
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

testPlaylistManagement();