#!/usr/bin/env bash
###############################################################################
# update-cmd.sh
#
# Standalone bash test for `bulkhead update` on the host. code-server and caddy
# are built from this repository and tagged `:local`, so no registry has them:
# a plain `docker compose pull` fails on them, and under `set -e` the update
# stopped there, before the rebuild. A stub `docker` on PATH stands in for
# Compose and records every call, so this runs without Docker.
###############################################################################

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"

PASS=0
FAIL=0
check() { # <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/bin"

# Behaves like Compose for the calls `bulkhead update` makes: `pull --help` lists
# --ignore-buildable only when STUB_IGNORE_BUILDABLE=1 (Compose 2.22 and later);
# a plain pull fails on the images built here; an unknown flag fails.
cat >"${TMP}/bin/docker" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"${DOCKER_LOG}"
case "$*" in
  "compose pull --help")
    [ "${STUB_IGNORE_BUILDABLE}" = 1 ] && echo "      --ignore-buildable       Ignore images that can be built"
    echo "      --ignore-pull-failures   Pull what it can and ignores images with pull failures"
    exit 0 ;;
  *" pull --ignore-buildable") [ "${STUB_IGNORE_BUILDABLE}" = 1 ] || { echo "unknown flag: --ignore-buildable" >&2; exit 1; } ;;
  *" pull --ignore-pull-failures") ;;
  *" pull") echo "pull access denied for inferhaven/code-server" >&2; exit 1 ;;
esac
exit 0
EOF
chmod +x "${TMP}/bin/docker"

run_update() { # <1 if Compose knows --ignore-buildable>
  : >"${TMP}/log"
  DOCKER_LOG="${TMP}/log" STUB_IGNORE_BUILDABLE="$1" PATH="${TMP}/bin:${PATH}" \
    "${ROOT}/scripts/bulkhead" update >/dev/null 2>&1
}

COMPOSE="compose -f ${ROOT}/docker-compose.yml"

run_update 1
check "Compose 2.22+: update succeeds" "0" "$?"
check "Compose 2.22+: pulls only what it does not build" "${COMPOSE} pull --ignore-buildable" "$(grep "^${COMPOSE} pull" "${TMP}/log")"
check "Compose 2.22+: then rebuilds and restarts" "${COMPOSE} up -d --build" "$(tail -1 "${TMP}/log")"

run_update 0
check "older Compose v2: update succeeds" "0" "$?"
check "older Compose v2: pull skips what it cannot fetch" "${COMPOSE} pull --ignore-pull-failures" "$(grep "^${COMPOSE} pull" "${TMP}/log")"
check "older Compose v2: then rebuilds and restarts" "${COMPOSE} up -d --build" "$(tail -1 "${TMP}/log")"

echo "update-cmd: ${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
