#!/usr/bin/env bash
# Local Kata Containers helpers: install the GitHub static release, wire
# containerd, and run/shell into an Ubuntu container on the Kata runtime.
#
#   kata-install [VERSION]     download + install to /opt/kata
#   kata-cleanup               remove leftover containers, cache, and /opt/kata
#   kata-status                show runtime / containerd / kvm
#   kata-ubuntu [--keep]       interactive Ubuntu shell via Kata
set -euo pipefail

KATA_PREFIX="${KATA_PREFIX:-/opt/kata}"
# Latest stable static release (https://github.com/kata-containers/kata-containers/releases).
DEFAULT_KATA_VERSION="${KATA_VERSION:-4.0.0}"
KATA_REPO="${KATA_REPO:-kata-containers/kata-containers}"
KATA_RUNTIME="${KATA_RUNTIME:-io.containerd.kata.v2}"
CONTAINERD_SOCKET="${CONTAINERD_SOCKET:-/run/containerd/containerd.sock}"
DEFAULT_IMAGE="${KATA_UBUNTU_IMAGE:-docker.io/library/ubuntu:24.04}"
DEFAULT_NAME="${KATA_UBUNTU_NAME:-kata-ubuntu}"
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/kata-containers"

die() {
  echo "error: $*" >&2
  exit 1
}

info() {
  echo "$*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    need_cmd sudo
    sudo "$@"
  fi
}

host_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64 | arm64) echo arm64 ;;
    ppc64le) echo ppc64le ;;
    s390x) echo s390x ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
}

github_api() {
  local path="$1"
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -A "nix-config-kata" \
    "https://api.github.com/repos/${KATA_REPO}${path}"
}

latest_stable_tag() {
  github_api "/releases" | jq -r '
    [
      .[]
      | select(.prerelease == false and .draft == false)
      | .tag_name
      | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
    ][0] // empty
  '
}

shim_bin() {
  echo "${KATA_PREFIX}/bin/containerd-shim-kata-v2"
}

ctr_bin() {
  command -v ctr || die "ctr not found (containerd client)"
}

ctr_root() {
  as_root "$(ctr_bin)" --address "$CONTAINERD_SOCKET" "$@"
}

# Replace this process with ctr (sudo if needed). Functions cannot be exec'd.
exec_ctr_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    exec "$(ctr_bin)" --address "$CONTAINERD_SOCKET" "$@"
  else
    need_cmd sudo
    exec sudo "$(ctr_bin)" --address "$CONTAINERD_SOCKET" "$@"
  fi
}

require_kvm() {
  [[ -e /dev/kvm ]] || die "/dev/kvm is missing; load kvm-amd or kvm-intel"
}

require_shim_runs() {
  local bin out
  [[ -x "$(shim_bin)" ]] || die "Kata is not installed; run kata-install first"
  bin="${KATA_PREFIX}/bin/kata-runtime"
  [[ -x "$bin" ]] || bin="$(shim_bin)"
  out="$(as_root "$bin" --version 2>&1 || true)"
  if grep -q "NixOS cannot run dynamically linked executables" <<<"$out"; then
    die "NixOS blocked ${bin} (generic Linux ELF).
Enable nix-ld on the host and rebuild, then retry:

  programs.nix-ld.enable = true;
  systemd.services.containerd.environment.NIX_LD = \"/run/current-system/sw/share/nix-ld/lib/ld.so\";
  systemd.services.containerd.environment.NIX_LD_LIBRARY_PATH = \"/run/current-system/sw/share/nix-ld/lib:/opt/kata/lib:/opt/kata/lib64\";

  sudo nixos-rebuild switch --flake /etc/nixos#\$(hostname)"
  fi
}

require_containerd() {
  [[ -S "$CONTAINERD_SOCKET" ]] || die "containerd is not running (${CONTAINERD_SOCKET}).
On NixOS, add to the host config and rebuild:

  virtualisation.containerd.enable = true;
  systemd.services.containerd.path = [ \"/opt/kata\" ];"
}

containerd_has_kata_path() {
  systemctl show containerd -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | grep -q '^PATH=.*'"${KATA_PREFIX}/bin"
}

configure_containerd_path() {
  need_cmd systemctl
  if ! systemctl list-unit-files containerd.service >/dev/null 2>&1; then
    info "containerd.service not installed; skip PATH drop-in"
    info "On NixOS, enable virtualisation.containerd.enable and rebuild."
    return 0
  fi

  if containerd_has_kata_path; then
    info "containerd already has ${KATA_PREFIX}/bin on PATH"
    return 0
  fi

  local current dropin
  current="$(systemctl show containerd -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | sed -n 's/^PATH=//p' \
    | head -n1)"
  if [[ -z "$current" ]]; then
    current="/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin"
  fi

  local nix_ld="${NIX_LD:-/run/current-system/sw/share/nix-ld/lib/ld.so}"
  local nix_ld_libs="${NIX_LD_LIBRARY_PATH:-/run/current-system/sw/share/nix-ld/lib}:${KATA_PREFIX}/lib:${KATA_PREFIX}/lib64"

  dropin=/etc/systemd/system/containerd.service.d/kata.conf
  info "writing ${dropin}"
  as_root mkdir -p "$(dirname "$dropin")"
  as_root tee "$dropin" >/dev/null <<EOF
# Added by kata-install (nix-config). Prepends the Kata static prefix so
# containerd can resolve containerd-shim-kata-v2, and passes nix-ld so
# generic Linux ELFs can run on NixOS.
[Service]
Environment=PATH=${KATA_PREFIX}/bin:${current}
Environment=NIX_LD=${nix_ld}
Environment=NIX_LD_LIBRARY_PATH=${nix_ld_libs}
EOF
  as_root systemctl daemon-reload
  as_root systemctl restart containerd
  info "restarted containerd"
}

extract_static() {
  local archive="$1"
  local name="$2"
  local extract
  local -a decompress

  case "$name" in
    *.tar.zst)
      need_cmd zstd
      decompress=(zstd -d -c)
      ;;
    *.tar.xz)
      need_cmd xz
      decompress=(xz -d -c)
      ;;
    *)
      die "unhandled archive type: ${name}"
      ;;
  esac

  if [[ "$KATA_PREFIX" == "/opt/kata" ]]; then
    "${decompress[@]}" "$archive" | as_root tar -C / -xp
    return 0
  fi

  extract="$(mktemp -d "${CACHE_DIR}/extract.XXXXXX")"
  "${decompress[@]}" "$archive" | tar -C "$extract" -xp
  [[ -d "${extract}/opt/kata" ]] || die "archive did not contain opt/kata"
  as_root mkdir -p "$(dirname "$KATA_PREFIX")"
  as_root rm -rf "$KATA_PREFIX"
  as_root mv "${extract}/opt/kata" "$KATA_PREFIX"
  rm -rf "$extract"
}

link_kata_bins() {
  local bin
  as_root mkdir -p /usr/local/bin
  for bin in containerd-shim-kata-v2 kata-runtime kata-collect-data.sh; do
    if [[ -e "${KATA_PREFIX}/bin/${bin}" ]]; then
      as_root ln -sfn "${KATA_PREFIX}/bin/${bin}" "/usr/local/bin/${bin}"
    fi
  done
}

cmd_install() {
  local version="$DEFAULT_KATA_VERSION" yes=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y | --yes)
        yes=1
        shift
        ;;
      --latest)
        version=""
        shift
        ;;
      -h | --help)
        cat <<EOF
Usage: kata-install [-y] [--latest] [VERSION]

Download the Kata Containers static release tarball from GitHub and install
it under /opt/kata (override with KATA_PREFIX). Wires containerd so
\`ctr run --runtime io.containerd.kata.v2\` can find the shim.

VERSION defaults to ${DEFAULT_KATA_VERSION}. Pass --latest to resolve the
newest stable GitHub release instead.
EOF
        return 0
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        version="$1"
        shift
        ;;
    esac
  done

  need_cmd curl
  need_cmd jq
  need_cmd tar
  require_kvm

  if [[ -z "$version" ]]; then
    info "resolving latest stable Kata release…"
    version="$(latest_stable_tag)"
    [[ -n "$version" ]] || die "could not determine latest stable release from GitHub"
  fi

  local arch asset_json url name size
  arch="$(host_arch)"
  info "looking up kata-static ${version} (${arch})…"
  asset_json="$(github_api "/releases/tags/${version}" | jq -c --arg arch "$arch" '
    [.assets[]
      | select(.name | test("kata-static-.*-" + $arch + "\\.tar\\.(zst|xz)$"))]
    | .[0] // empty
  ')"
  [[ -n "$asset_json" && "$asset_json" != "null" ]] \
    || die "no kata-static tarball for ${version} ${arch} on GitHub"

  url="$(jq -r '.browser_download_url' <<<"$asset_json")"
  name="$(jq -r '.name' <<<"$asset_json")"
  size="$(jq -r '.size' <<<"$asset_json")"

  info "release:  ${version}"
  info "asset:    ${name} ($(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size} bytes"))"
  info "prefix:   ${KATA_PREFIX}"

  if [[ "$yes" -ne 1 ]]; then
    read -r -p "Download and install to ${KATA_PREFIX}? [y/N] " reply
    [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]] || die "aborted"
  fi

  mkdir -p "$CACHE_DIR"
  local archive="${CACHE_DIR}/${name}"
  if [[ -f "$archive" && "$(stat -c%s "$archive" 2>/dev/null || echo 0)" == "$size" ]]; then
    info "using cached ${archive}"
  else
    info "downloading ${url}"
    curl -fL --progress-bar -C - -o "${archive}.part" "$url"
    mv "${archive}.part" "$archive"
  fi

  if [[ -e "$KATA_PREFIX" ]]; then
    info "replacing existing ${KATA_PREFIX}"
    as_root rm -rf "$KATA_PREFIX"
  fi

  info "extracting to ${KATA_PREFIX}…"
  extract_static "$archive" "$name"

  [[ -x "$(shim_bin)" ]] || die "install completed but $(shim_bin) is missing"

  link_kata_bins
  configure_containerd_path
  require_shim_runs

  info ""
  as_root "${KATA_PREFIX}/bin/kata-runtime" --version || true
  info "installed. Next: kata-ubuntu"
}

cmd_cleanup() {
  local yes=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y | --yes)
        yes=1
        shift
        ;;
      -h | --help)
        cat <<'EOF'
Usage: kata-cleanup [-y]

Stop leftover Kata containers, then remove:
  /opt/kata
  /usr/local/bin/{containerd-shim-kata-v2,kata-runtime,kata-collect-data.sh}
  /etc/systemd/system/containerd.service.d/kata.conf
  the download cache under ~/.cache/kata-containers
EOF
        return 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
  done

  if [[ "$yes" -ne 1 ]]; then
    read -r -p "Remove ${KATA_PREFIX}, Kata containers, cache, and containerd drop-in? [y/N] " reply
    [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]] || die "aborted"
  fi

  if [[ -S "$CONTAINERD_SOCKET" ]] && command -v ctr >/dev/null 2>&1; then
    info "removing leftover container ${DEFAULT_NAME}"
    remove_container "$DEFAULT_NAME" || true
  fi

  info "removing ${KATA_PREFIX}"
  as_root rm -rf "$KATA_PREFIX"
  as_root rm -f \
    /usr/local/bin/containerd-shim-kata-v2 \
    /usr/local/bin/kata-runtime \
    /usr/local/bin/kata-collect-data.sh
  as_root rm -f /etc/systemd/system/containerd.service.d/kata.conf
  rm -rf "$CACHE_DIR"
  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files containerd.service >/dev/null 2>&1; then
    as_root systemctl daemon-reload
    as_root systemctl restart containerd || true
  fi
  info "cleaned up ${KATA_PREFIX}"
}

cmd_status() {
  echo "prefix:      ${KATA_PREFIX}"
  if [[ -x "$(shim_bin)" ]]; then
    echo "shim:        $(shim_bin)"
    as_root "${KATA_PREFIX}/bin/kata-runtime" --version 2>/dev/null | sed 's/^/             /' || true
  else
    echo "shim:        not installed (run kata-install)"
  fi

  if [[ -e /dev/kvm ]]; then
    echo "kvm:         /dev/kvm"
  else
    echo "kvm:         missing"
  fi

  if [[ -S "$CONTAINERD_SOCKET" ]]; then
    echo "containerd:  ${CONTAINERD_SOCKET}"
    if containerd_has_kata_path 2>/dev/null; then
      echo "shim PATH:   containerd has ${KATA_PREFIX}/bin"
    else
      echo "shim PATH:   ${KATA_PREFIX}/bin not on containerd PATH"
    fi
  else
    echo "containerd:  not running"
  fi
}

container_exists() {
  ctr_root containers info "$1" >/dev/null 2>&1
}

task_running() {
  ctr_root tasks ls | awk 'NR>1 { print $1 }' | grep -qx "$1"
}

remove_container() {
  local name="$1"
  ctr_root tasks kill --signal SIGKILL "$name" >/dev/null 2>&1 || true
  # Wait briefly for the task to exit so container delete succeeds.
  for _ in 1 2 3 4 5; do
    task_running "$name" || break
    sleep 0.2
  done
  ctr_root tasks delete "$name" >/dev/null 2>&1 || true
  ctr_root containers delete "$name" >/dev/null 2>&1 || true
}

cmd_ubuntu() {
  local name="$DEFAULT_NAME"
  local image="$DEFAULT_IMAGE"
  local keep=0
  local -a cmd=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)
        [[ $# -ge 2 ]] || die "--name requires an argument"
        name="$2"
        shift 2
        ;;
      --image)
        [[ $# -ge 2 ]] || die "--image requires an argument"
        image="$2"
        shift 2
        ;;
      --keep)
        keep=1
        shift
        ;;
      -h | --help)
        cat <<'EOF'
Usage: kata-ubuntu [--keep] [--name NAME] [--image IMAGE] [-- CMD...]

Pull IMAGE (default ubuntu:24.04) and run it with the Kata containerd
runtime. With no command, opens an interactive /bin/bash.

  --keep    leave the container running; re-running kata-ubuntu execs into it
  --name    containerd container id (default: kata-ubuntu)
  --image   image to pull (default: docker.io/library/ubuntu:24.04)

Requires: kata-install, a running containerd, and /dev/kvm.
EOF
        return 0
        ;;
      --)
        shift
        cmd=("$@")
        break
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        cmd+=("$1")
        shift
        ;;
    esac
  done

  [[ ${#cmd[@]} -eq 0 ]] && cmd=(/bin/bash)

  require_kvm
  require_containerd
  require_shim_runs

  info "pulling ${image}"
  ctr_root images pull "$image"

  if [[ "$keep" -eq 1 ]]; then
    if ! task_running "$name"; then
      if container_exists "$name"; then
        info "starting existing container ${name}"
        ctr_root tasks start "$name" >/dev/null
      else
        info "creating ${name} with ${KATA_RUNTIME}"
        ctr_root run -d --runtime "$KATA_RUNTIME" "$image" "$name" sleep infinity
      fi
    fi
    info "exec into ${name}"
    exec_ctr_root tasks exec -t --exec-id "shell-$$" "$name" "${cmd[@]}"
  fi

  remove_container "$name"
  info "running ${name} with ${KATA_RUNTIME} (removed on exit)"
  exec_ctr_root run --runtime "$KATA_RUNTIME" --rm -t "$image" "$name" "${cmd[@]}"
}

usage() {
  cat <<'EOF'
Usage: kata <install|cleanup|status|ubuntu> [args...]

Commands:
  install [VERSION]   install Kata 4.0.0 static release under /opt/kata
  cleanup             remove leftover containers, cache, and /opt/kata
  status              show Kata / containerd / kvm
  ubuntu              interactive Ubuntu shell via the Kata runtime

Wrappers: kata-install, kata-cleanup, kata-status, kata-ubuntu
EOF
}

main() {
  local sub="${1:-}"
  if [[ -n "$sub" ]]; then
    shift
  fi
  case "$sub" in
    install) cmd_install "$@" ;;
    cleanup | uninstall) cmd_cleanup "$@" ;;
    status) cmd_status "$@" ;;
    ubuntu) cmd_ubuntu "$@" ;;
    -h | --help | "") usage ;;
    *)
      usage >&2
      die "unknown command: ${sub}"
      ;;
  esac
}

main "$@"
