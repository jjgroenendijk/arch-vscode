#!/usr/bin/env bash
set -euo pipefail
set -E

COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.test.yml}
SERVICE_NAME=${SERVICE_NAME:-arch-vscode-test}
EXPECTED_USER=${EXPECTED_USER:-usert}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

mkdir -p test-workspace test-home

FAILED=0
trap 'FAILED=1' ERR
cleanup() {
  local exit_code=$FAILED
  if [ "$FAILED" -eq 1 ]; then
    compose logs "$SERVICE_NAME" || true
  fi
  compose down --volumes --remove-orphans || true
  exit $exit_code
}
trap cleanup EXIT

retry() {
  local attempts=$1
  shift
  local attempt=1
  while true; do
    set +e
    "$@" 2>&1
    local status=$?
    set -e
    if [ $status -eq 0 ]; then
      echo "[retry] Command succeeded on attempt $attempt" >&2
      return 0
    fi
    echo "[retry] Attempt $attempt/$attempts failed (exit $status), retrying..." >&2
    if [ "$attempt" -ge "$attempts" ]; then
      echo "[retry] All attempts exhausted" >&2
      return 1
    fi
    attempt=$((attempt + 1))
    sleep 5
  done
}

wait_for_running() {
  [[ "$(docker inspect -f '{{.State.Status}}' "$SERVICE_NAME")" == "running" ]]
}

compose down --volumes --remove-orphans || true
compose up -d

retry 12 wait_for_running
FAILED=0

assert_user() {
  [[ "$(compose exec -T --user "$EXPECTED_USER" "$SERVICE_NAME" bash -lc 'whoami')" == "$EXPECTED_USER" ]]
}

retry 12 assert_user
FAILED=0

retry 12 compose exec -T --user "$EXPECTED_USER" "$SERVICE_NAME" bash -lc 'npm --version' >/dev/null
FAILED=0
compose exec -T --user "$EXPECTED_USER" "$SERVICE_NAME" test -d "/home/$EXPECTED_USER"
compose exec -T --user "$EXPECTED_USER" "$SERVICE_NAME" test -d /workspace

# Verify that VS Code default workspace is mounted by checking contents
compose exec -T --user "$EXPECTED_USER" "$SERVICE_NAME" bash -lc 'ls -A /workspace' >/dev/null
