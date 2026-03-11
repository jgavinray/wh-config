# wh-config

Configuration and setup files for the Zapp whisper transcription pipeline.

## Contents

- `zapp/` — Zapp (Jetson Orin) service configs and scripts
  - `whisper-server-wrapper.sh` — manages whisper-server lifecycle (stops llama-server, starts whisper, restores llama on exit)
  - `whisper.service` — systemd unit for whisper-server persistence across reboots

## Setup

See individual files for deployment instructions.

## Architecture

- **Zapp**: NVIDIA Jetson Orin (YOUR_ZAPP_LAN_IP), running whisper.cpp on GPU
- **Model**: ggml-large-v3-turbo.bin at `/home/jgavinray/whisper.cpp/models/`
- **Endpoint**: `http://YOUR_ZAPP_LAN_IP:8081/inference` (LAN accessible)
