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
- **Model**: ggml-large-v3-turbo.bin at `${HOME}/whisper.cpp/models/`
- **Endpoint**: `http://YOUR_ZAPP_LAN_IP:8081/inference` (LAN accessible)

## Prometheus Exporters

### Overview

Automated deployment of Prometheus exporters for fleet monitoring:
- **node_exporter** (port 9100) — System metrics (CPU, memory, disk, network)
- **dcgm_exporter** (port 9400) — NVIDIA GPU metrics (via DCGM)

### Usage

1. Edit `ansible/inventory.ini` and replace placeholder IPs with actual LAN addresses:
   ```ini
   [spark]
   YOUR_SPARK_LAN_IP ansible_host=YOUR_SPARK_LAN_IP

   [zapp]
   YOUR_ZAPP_LAN_IP ansible_host=YOUR_ZAPP_LAN_IP
   ```

2. Run the playbook:
   ```bash
   cd ~/dev/wh-config
   ansible-playbook -i ansible/inventory.ini ansible/playbooks/prometheus-exporters.yml
   ```

3. Dry-run (check mode) before actual deployment:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbooks/prometheus-exporters.yml --check
   ```

### Idempotency

The playbook is fully idempotent:
- Skips download/install if binaries already exist
- Only restarts services on config changes
- Safe to run multiple times

### Version Pins

See `ansible/playbooks/vars/versions.yml` for exporter versions:
- node_exporter: 1.8.x
- dcgm_exporter: latest

## Variables & Placeholders

| Variable | Description | Example |
|----------|-------------|---------|
| `${USER}` | Local username | jgavinray |
| `${HOME}` | Home directory | /Users/jgavinray |
| `YOUR_SPARK_LAN_IP` | Spark node LAN IP | 192.168.x.x |
| `YOUR_ZAPP_LAN_IP` | Zapp node LAN IP | 192.168.x.x |
