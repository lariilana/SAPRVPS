#!/usr/bin/env node

// Temporary script to run the standalone server on port 5001 for testing
const { spawn } = require('child_process');
const path = require('path');

console.log('Starting Sa Plays Roblox Streamer Standalone Server...');
console.log('This will run on port 5001 to avoid conflicts with the main server');

// Set environment variable to use port 5001
process.env.STANDALONE_PORT = '5001';

// Run the standalone server
const standaloneProcess = spawn('node', [path.join(__dirname, 'server-standalone.cjs')], {
  stdio: 'inherit',
  env: { ...process.env, PORT: '5001', STANDALONE_PORT: '5001' }
});

standaloneProcess.on('error', (error) => {
  console.error('Failed to start standalone server:', error);
  process.exit(1);
});

standaloneProcess.on('exit', (code) => {
  console.log(`Standalone server exited with code ${code}`);
  process.exit(code);
});

// Handle cleanup
process.on('SIGINT', () => {
  console.log('\nShutting down standalone server...');
  standaloneProcess.kill('SIGINT');
});

process.on('SIGTERM', () => {
  console.log('\nShutting down standalone server...');
  standaloneProcess.kill('SIGTERM');
});