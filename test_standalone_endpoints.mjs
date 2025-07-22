// Quick test of all standalone server endpoints
const BASE_URL = 'http://localhost:3000';

const endpoints = [
  'GET /api/stream-status',
  'GET /api/videos', 
  'GET /api/stream-config',
  'GET /api/system-config',
  'POST /api/stream/loop/enable',
  'GET /api/stream/loop/status',
  'POST /api/stream/loop/disable'
];

console.log('🧪 Testing Standalone Server Endpoints\n');

for (const endpoint of endpoints) {
  const [method, path] = endpoint.split(' ');
  
  try {
    const options = { method };
    if (method === 'POST') {
      options.headers = { 'Content-Type': 'application/json' };
    }
    
    const response = await fetch(`${BASE_URL}${path}`, options);
    const result = await response.text();
    
    const status = response.status < 400 ? '✅' : '❌';
    console.log(`${status} ${endpoint} - Status: ${response.status}`);
    
    if (result) {
      const preview = result.substring(0, 80);
      console.log(`   Response: ${preview}${result.length > 80 ? '...' : ''}`);
    }
  } catch (error) {
    console.log(`❌ ${endpoint} - Error: ${error.message}`);
  }
}

console.log('\n🎬 All tests completed!');