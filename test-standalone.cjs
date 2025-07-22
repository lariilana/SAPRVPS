#!/usr/bin/env node

const http = require('http');
const { spawn } = require('child_process');

// Test the standalone server
async function testStandalone() {
  console.log('Starting standalone server test...');
  
  // Start the server
  const serverProcess = spawn('node', ['server-standalone.cjs'], {
    stdio: 'inherit',
    detached: false
  });
  
  // Wait for server to start
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  const tests = [
    { name: 'Health Check', url: '/health' },
    { name: 'Videos API', url: '/api/videos' },
    { name: 'Stream Status', url: '/api/stream-status' },
    { name: 'Stream Config', url: '/api/stream-config' },
    { name: 'System Config', url: '/api/system-config' }
  ];
  
  let passedTests = 0;
  const totalTests = tests.length;
  
  for (const test of tests) {
    try {
      const response = await makeRequest(test.url);
      console.log(`✅ ${test.name}: ${response.status} - ${response.data.substring(0, 100)}...`);
      passedTests++;
    } catch (error) {
      console.log(`❌ ${test.name}: ${error.message}`);
    }
  }
  
  console.log(`\nTest Results: ${passedTests}/${totalTests} tests passed`);
  
  // Kill server
  serverProcess.kill();
  process.exit(passedTests === totalTests ? 0 : 1);
}

function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: 'GET'
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          data: data
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
    
    req.end();
  });
}

testStandalone();