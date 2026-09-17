#!/usr/bin/env bash
# Locate the Isabelle executable. Sourced by the other scripts; not run.
#
# Isabelle has no single install location and is not usually on PATH after a
# tarball unpack, so look in the three places a checkout of this repository is
# plausibly built from, most explicit first.

iogos_find_isabelle() {
  if [[ -n "${ISABELLE:-}" ]]; then
    if [[ ! -x "$ISABELLE" ]]; then
      echo "error: ISABELLE is set to $ISABELLE, which is not executable" >&2
      return 1
    fi
    printf '%s\n' "$ISABELLE"
    return 0
  fi
  local found
  if found="$(command -v isabelle 2>/dev/null)"; then
    printf '%s\n' "$found"
    return 0
  fi
  if [[ -x "$HOME/isabelle/bin/isabelle" ]]; then
    printf '%s\n' "$HOME/isabelle/bin/isabelle"
    return 0
  fi
  cat >&2 <<'MSG'
error: no Isabelle found.

Looked at $ISABELLE, then isabelle on PATH, then ~/isabelle/bin/isabelle.
Set ISABELLE to the executable, or put it on PATH. Isabelle2025-2 is the
version this tree is developed against; see README.md.
MSG
  return 1
}
