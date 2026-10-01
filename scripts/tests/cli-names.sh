#!/usr/bin/env bash
###############################################################################
# cli-names.sh
#
# Standalone bash test for the CLI's names: `bulkhead` is the command, `bh`
# its short form, and `haven` the old name, which prints one notice on stderr
# and then runs the same command. Runs on a dev host without Docker: the host
# scripts run for real; the workspace side is checked through its wrapper
# (against a stub CLI) and the Dockerfile lines that install the three names.
###############################################################################

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
NOTICE="This command is now 'bulkhead' (short: 'bh'). 'haven' still works."

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

# ── Host: all three names run the same CLI ───────────────────────────────────
for name in bulkhead bh haven; do
  out="$("${ROOT}/scripts/${name}" version 2>"${TMP}/err")"
  check "host ${name}: version" "Bulkhead v0.1.0" "${out}"
done
"${ROOT}/scripts/bulkhead" version 2>"${TMP}/err" >/dev/null
check "host bulkhead: stderr stays empty" "" "$(cat "${TMP}/err")"
"${ROOT}/scripts/bh" version 2>"${TMP}/err" >/dev/null
check "host bh: stderr stays empty" "" "$(cat "${TMP}/err")"
"${ROOT}/scripts/haven" version 2>"${TMP}/err" >/dev/null
check "host haven: prints the notice once, on stderr" "${NOTICE}" "$(cat "${TMP}/err")"
BULKHEAD_RENAME_NOTICE=0 "${ROOT}/scripts/haven" version 2>"${TMP}/err" >/dev/null
check "host haven: BULKHEAD_RENAME_NOTICE=0 silences the notice" "" "$(cat "${TMP}/err")"

help="$("${ROOT}/scripts/bulkhead" help 2>/dev/null)"
check "host help: usage names bulkhead" "1" "$(grep -c "Usage: bulkhead <command> \[args\]" <<<"${help}")"
check "host help: names the short form" "1" "$(grep -c "Short form: 'bh'" <<<"${help}")"

# ── Workspace: the old-name wrapper passes every argument through ────────────
mkdir -p "${TMP}/bin"
cp "${ROOT}/docker/workspace/scripts/haven-alias.sh" "${TMP}/bin/haven"
printf '#!/bin/sh\nprintf "%%s|" "$@"\n' >"${TMP}/bin/bulkhead"
chmod +x "${TMP}/bin/haven" "${TMP}/bin/bulkhead"
out="$("${TMP}/bin/haven" tune 'model with spaces' --dry-run 2>"${TMP}/err")"
check "workspace haven: runs bulkhead with the same arguments" "tune|model with spaces|--dry-run|" "${out}"
check "workspace haven: prints the notice once, on stderr" "${NOTICE}" "$(cat "${TMP}/err")"
BULKHEAD_RENAME_NOTICE=0 "${TMP}/bin/haven" status 2>"${TMP}/err" >/dev/null
check "workspace haven: BULKHEAD_RENAME_NOTICE=0 silences the notice" "" "$(cat "${TMP}/err")"

# ── Workspace: the image installs all three names ────────────────────────────
DF="${ROOT}/docker/workspace/Dockerfile"
check "image: the CLI is installed as bulkhead" "1" "$(grep -cE '^COPY --link scripts/haven\.sh +/usr/local/bin/bulkhead$' "${DF}")"
check "image: the old name is the wrapper" "1" "$(grep -cE '^COPY --link scripts/haven-alias\.sh +/usr/local/bin/haven$' "${DF}")"
check "image: bh points at bulkhead" "1" "$(grep -cE 'ln -s bulkhead /usr/local/bin/bh' "${DF}")"

# ── No script still tells anyone to run the old name ─────────────────────────
SUBCOMMANDS='aider|apt|backup|bench|caddy|chat|claude|copy|cp|devcontainer|doctor|down|goose|gpu|gpu-info|harness|help|ide|limits|login|logout|logs|models|nest|params|ps|pull|pullback|push|qwen|remove|reset|restart|rm|run|service|session|show|signin|signout|ssh|ssh-key|starship|status|sync|tmate|tmux|tune|unload|untune|up|update|version'
left="$(grep -rnE "(^|[^a-zA-Z0-9_./-])haven (${SUBCOMMANDS})([^a-z-]|$)" \
  "${ROOT}/scripts/bulkhead" "${ROOT}/docker" "${ROOT}/Makefile" \
  | grep -v 'haven-alias\.sh:' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
check "no 'haven <command>' left in the CLI, the images or the Makefile" "" "${left}"
check "no './scripts/haven' left in what users read (comments may name it)" "" \
  "$(grep -rn '\./scripts/haven\b' "${ROOT}/scripts/bulkhead" "${ROOT}/docker" "${ROOT}/Makefile" \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"

check "nothing in the image calls the old name by its full path" "" \
  "$(grep -rnE '/usr/local/bin/haven([^-a-z]|$)' "${ROOT}/docker" | grep -v '/Dockerfile:' \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"

DOCS=("${ROOT}/README.md" "${ROOT}/CONTRIBUTING.md" "${ROOT}/SECURITY.md" "${ROOT}/docs" "${ROOT}/.devcontainer" "${ROOT}/.github")
check "the docs name the command bulkhead" "" \
  "$(grep -rnE "(^|[^a-zA-Z0-9_./-])haven (${SUBCOMMANDS})([^a-z-]|$)|\./scripts/haven\b" "${DOCS[@]}" || true)"

# The product's old names stay only in the README's note for people who knew them.
check "no 'InferHaven Core' or 'InferHaven Cloud' outside the README's rename note" "" \
  "$(git -C "${ROOT}" grep -nE 'InferHaven (Core|Cloud)' -- . ':!LICENSE' ':!scripts/tests/cli-names.sh' | grep -v '^README.md:[0-9]*:> This project was previously called' || true)"

# ── The repository is InferHaven/bulkhead, and a fresh clone is a folder named bulkhead ──
# The devcontainer's folder inside the container keeps its old path on purpose
# (/home/haven/projects/inferhaven-core: compose binds the checkout there whatever it is called).
NOT_ME=(-- . ':!scripts/tests/cli-names.sh')
check "no link to the repository's old name" "" \
  "$(git -C "${ROOT}" grep -nE 'InferHaven/inferhaven-core' "${NOT_ME[@]}" || true)"
check "no clone folder named inferhaven-core in the docs or comments" "" \
  "$(git -C "${ROOT}" grep -nE '(^|[^/a-z-])inferhaven-core(/|$)' "${NOT_ME[@]}" || true)"
# shellcheck disable=SC2016  # the backticks are literal Markdown, matched as text
check "nothing calls the product inferhaven-core" "" \
  "$(git -C "${ROOT}" grep -nE '\*\*inferhaven-core\*\*|`inferhaven-core`' "${NOT_ME[@]}" || true)"
# shellcheck disable=SC2016  # the backticks are literal Markdown, matched as text
check "the docs call the CLI bulkhead" "" \
  "$(grep -rnE '`haven` CLI|CLI \(`haven`\)|file `haven` writes' "${DOCS[@]}" || true)"

echo "cli-names: ${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
