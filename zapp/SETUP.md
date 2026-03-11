# Zapp Whisper Setup

Setup guide for whisper.cpp on NVIDIA Jetson Orin (aarch64, JetPack 6, CUDA 12.6).

## Hardware

- **Device**: NVIDIA Jetson Orin
- **Hostname**: zapp (YOUR_ZAPP_LAN_IP LAN, YOUR_ZAPP_TAILSCALE_IP)
- **CUDA**: 12.6, compute capability sm_87
- **RAM**: 7.4GB unified memory (shared CPU/GPU)

## Prerequisites

```bash
# Required on Zapp
sudo apt install cmake build-essential libcurl4-openssl-dev
# CUDA toolkit already present via JetPack
```

## Build whisper.cpp

```bash
cd ~
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
mkdir build && cd build

# CRITICAL: must specify CUDA_ARCHITECTURES=870 for Jetson Orin (sm_87)
# Without this it builds CPU-only
cmake .. \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES=870 \
  -DWHISPER_BUILD_SERVER=ON

cmake --build . --config Release -j$(nproc)
```

### Known challenges

**Tailscale blocks SSH from Mac mini to Zapp** — tailnet policy prevents it. Always SSH via LAN (YOUR_ZAPP_LAN_IP), not Tailscale IP (YOUR_ZAPP_TAILSCALE_IP).

**GPU memory contention** — whisper-server and llama-server cannot both run simultaneously (OOM). The wrapper script handles this by stopping llama-server before starting whisper and restoring it on exit.

**`--gpu-compat` flag** — not supported by this build. Ignore it; CUDA is enabled by default when linked correctly.

**LD_LIBRARY_PATH** — if you get CUDA library errors running binaries manually, set:
```bash
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/targets/aarch64-linux/lib:$LD_LIBRARY_PATH
```
Not needed when running via systemd (env handled by wrapper).

**Build verification**:
```bash
ldd ~/whisper.cpp/build/bin/whisper-server | grep -E "cuda|cublas"
# Should show: libggml-cuda.so.0, libcudart.so.12, libcublas.so.12
```

## Download model

```bash
cd ~/whisper.cpp
bash models/download-ggml-model.sh large-v3-turbo
# Downloads to models/ggml-large-v3-turbo.bin (~1.6GB)
```

**Verify inference** (llama-server must be stopped first):
```bash
sudo systemctl stop llama-server
~/whisper.cpp/build/bin/whisper-cli \
  -m ~/whisper.cpp/models/ggml-large-v3-turbo.bin \
  -f ~/whisper.cpp/samples/jfk.wav
# Expected: ~3-4s on CUDA, correct JFK transcript
sudo systemctl start llama-server
```

## Deploy wrapper script

```bash
mkdir -p ~/bin
cp whisper-server-wrapper.sh ~/bin/
chmod +x ~/bin/whisper-server-wrapper.sh
```

## Deploy systemd service

```bash
sudo cp whisper.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable whisper.service
```

**Do not start via systemd if whisper-server is already running as a background process** — stop the background process first.

## Verify endpoint

```bash
# From Zapp or Mac (server binds 0.0.0.0:8081 — LAN accessible)
curl http://YOUR_ZAPP_LAN_IP:8081/health
# {"status":"ok"}

# Inference test
curl -s -F "file=@/path/to/audio.wav" http://YOUR_ZAPP_LAN_IP:8081/inference
```

## Current state (as of 2026-03-11)

- whisper.cpp built and working (sm_87 CUDA)
- ggml-large-v3-turbo.bin downloaded (1.6GB)
- whisper-server-wrapper.sh running as background process
- systemd service: **NOT yet deployed** (WH-11)
- Inference endpoint: http://YOUR_ZAPP_LAN_IP:8081 (reachable from Mac LAN)
