#!/usr/bin/env bash
# =============================================================================
# ci.sh — Build & Push Docker Image ke Docker Hub
#
# Jalankan dari dalam root repository project (yang berisi Dockerfile).
#
# Config:
#   Ubah DOCKER_ORG di bawah, atau export sebelum menjalankan script:
#   export DOCKER_ORG=myusername && ./ci.sh
#
# Usage:
#   ./ci.sh              → build + push
#   ./ci.sh --no-push    → build saja (tanpa push)
# =============================================================================

set -euo pipefail
export DOCKER_BUILDKIT=1

# ─── KONFIGURASI — sesuaikan bagian ini ──────────────────────────────────────
DOCKER_ORG="${DOCKER_ORG:-hegieswe}"     # ← Ganti dengan Docker Hub username/org Anda
PLATFORM="linux/amd64,linux/arm64"       # ← Multi-platform: AMD64 + ARM64 (Apple Silicon)
# ─────────────────────────────────────────────────────────────────────────────

# Warna
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
err()     { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}▶ $*${RESET}"; }

# Parse flag
PUSH=true
for arg in "$@"; do
  [[ "$arg" == "--no-push" ]] && PUSH=false
done

# ─── Auto-detect: REPO NAME dari nama folder git root ────────────────────────
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) \
  || err "Bukan git repository. Jalankan script dari dalam folder project."

DOCKER_REPO=$(basename "$GIT_ROOT")

# ─── Auto-detect: TAG dari git tag yang menunjuk ke commit saat ini ──────────
GIT_TAG=$(git tag --points-at HEAD 2>/dev/null | head -n1)

if [[ -n "$GIT_TAG" ]]; then
  DOCKER_TAG="$GIT_TAG"
  info "Tag dari git tag: ${BOLD}$DOCKER_TAG${RESET}"
else
  DOCKER_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
  warn "Tidak ada git tag pada commit ini. Menggunakan: ${BOLD}$DOCKER_TAG${RESET}"
fi

# ─── Validasi Dockerfile ─────────────────────────────────────────────────────
[[ -f "Dockerfile" ]] || err "Dockerfile tidak ditemukan di direktori ini: $(pwd)"

FULL_IMAGE="${DOCKER_ORG}/${DOCKER_REPO}:${DOCKER_TAG}"
LATEST_IMAGE="${DOCKER_ORG}/${DOCKER_REPO}:latest"

# ─── Ringkasan ───────────────────────────────────────────────────────────────
echo -e "\n${BOLD}═══════════════════════════════════════════${RESET}"
echo -e "${BOLD}  CI — Docker Build & Push${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════${RESET}"
info "Directory : $(pwd)"
info "Image     : ${BOLD}$FULL_IMAGE${RESET}"
info "Also tag  : ${BOLD}$LATEST_IMAGE${RESET}"
info "Platform  : $PLATFORM"
info "Push      : $PUSH"

# ─── Step 1: Docker Login ────────────────────────────────────────────────────
if [[ "$PUSH" == true ]]; then
  step "1/3 Docker Hub Login"
  if [[ -n "${DOCKER_PASSWORD:-}" && -n "${DOCKER_USERNAME:-}" ]]; then
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
    ok "Login berhasil."
  else
    warn "Env DOCKER_USERNAME/DOCKER_PASSWORD tidak diset. Menggunakan sesi login yang ada."
  fi
fi

# ─── Step 2: Build ───────────────────────────────────────────────────────────
step "2/3 Build & Push Image"
if [[ "$PUSH" == true ]]; then
  # Multi-platform build HARUS push langsung ke registry (tidak bisa load ke daemon lokal)
  info "Building & pushing: $FULL_IMAGE"
  BUILD_START=$(date +%s)
  docker buildx build \
    --platform "$PLATFORM" \
    --tag "$FULL_IMAGE" \
    --tag "$LATEST_IMAGE" \
    --push \
    .
else
  # Build saja tanpa push (single platform, bisa diload ke daemon lokal)
  info "Building (no push): $FULL_IMAGE"
  BUILD_START=$(date +%s)
  docker buildx build \
    --platform "linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    --tag "$FULL_IMAGE" \
    --tag "$LATEST_IMAGE" \
    --load \
    .
fi

BUILD_DURATION=$(( $(date +%s) - BUILD_START ))
ok "Build selesai dalam ${BUILD_DURATION}s"

IMAGE_SIZE=$(docker image inspect "$FULL_IMAGE" --format='{{.Size}}' \
  | awk '{printf "%.1f MB", $1/1024/1024}')
info "Ukuran image: ${BOLD}$IMAGE_SIZE${RESET}"

# ─── Step 3: Push ────────────────────────────────────────────────────────────
if [[ "$PUSH" == true ]]; then
  step "3/3 Selesai"
  ok "Push selesai! → https://hub.docker.com/r/${DOCKER_ORG}/${DOCKER_REPO}"
else
  warn "3/3 Push dilewati (--no-push)"
fi

echo -e "\n${GREEN}${BOLD}✅ CI selesai! Image: $FULL_IMAGE (${IMAGE_SIZE})${RESET}\n"
