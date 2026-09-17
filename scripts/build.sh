#!/usr/bin/env bash
# Build every session this tree registers in ROOTS.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build.sh [ISABELLE-BUILD-OPTION]...

Run `isabelle build -D .` over this repository. Extra arguments are passed
through to `isabelle build`, which is how the job and thread counts are bounded
on a machine with limited memory.

Examples:
  scripts/build.sh
  scripts/build.sh -j 2 -o threads=2
  scripts/build.sh -v Soundness
USAGE
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

# The calculus is installed rather than written here, and every session in this
# tree descends from it, so say what is missing instead of letting Isabelle
# report an unknown parent session.
if [[ ! -f "${repo_root}/Cpc/ROOT" ]]; then
  cat >&2 <<'MSG'
error: no calculus is installed; Cpc/ROOT is missing.

The CPC session is generated from the Eunoia definition of the calculus by an
Ethos checkout, not written here. Install it with:

  scripts/install.sh

See "Receiving a generated calculus" in README.md.
MSG
  exit 1
fi

# shellcheck source=isabelle-env.sh
source "${script_dir}/isabelle-env.sh"
isabelle="$(iogos_find_isabelle)"

cd "${repo_root}"
exec "${isabelle}" build -D . "$@"
