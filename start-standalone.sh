#!/bin/bash
echo "Stopping any existing servers..."
pkill -f "tsx server/index.ts"
pkill -f "server-standalone.cjs"

echo "Starting Sa Plays Roblox Streamer Standalone Server..."
DATABASE_URL=$DATABASE_URL node server-standalone.cjs