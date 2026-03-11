#!/bin/bash
# Wrapper for whisper-server that manages llama-server lifecycle

# Function to stop llama-server
stop_llama() {
    sudo systemctl stop llama-server.service 2>/dev/null || true
}

# Function to start llama-server
start_llama() {
    sleep 2
    sudo systemctl start llama-server.service 2>/dev/null || echo Failed to start llama-server
}

# Trap for EXIT (includes SIGTERM, SIGHUP via default behavior)
trap 'start_llama' EXIT

# Stop llama-server before starting whisper
stop_llama

# Run whisper-server (don't use exec so trap can fire)
/home/jgavinray/whisper.cpp/build/bin/whisper-server --host 0.0.0.0 --port 8081 --model /home/jgavinray/whisper.cpp/models/ggml-large-v3-turbo.bin
