#!/usr/bin/env bash
# Consistency of the specification under docs/spec.
#
#   scripts/check-spec.sh
#
# Always checked:
#   - the five specification files exist;
#   - every task block in TASKS.md (a "### T-PP.NN" heading) has the eight fields and a unique id;
#   - every PROGRESS.md row with status merged or open-green carries a link;
#   - a gate line that says "claimed" carries a link.
# Checked once DECISIONS.md says "Status: decided":
#   - no placeholder (text in double curly braces) is left in docs/spec, AGENTS.md or README.md.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SPEC=docs/spec
status=0
fail() { echo "check-spec: $*" >&2; status=1; }

for f in DECISIONS.md SPEC.md TASKS.md SUPERVISOR.md PROGRESS.md; do
  [ -f "$SPEC/$f" ] || fail "missing $SPEC/$f"
done
[ "$status" -eq 0 ] || exit "$status"

# Task blocks: from a "### T-" heading to the next heading or horizontal rule.
tasks_report="$(awk '
  function flush(   i, n, f) {
    if (id == "") return
    n = split("Executor:|Milestone:|Depends:|Read:|Files:|Do:|Accept:|Verify:", f, "|")
    for (i = 1; i <= n; i++) if (index(block, f[i]) == 0) printf "task %s has no \"%s\" field\n", id, f[i]
    if (seen[id]++) printf "task id %s is used more than once\n", id
    id = ""; block = ""
  }
  /^### T-/ { flush(); id = $2; block = ""; next }
  /^#/ || /^---/ || /^```/ { flush(); next }
  id != "" { block = block "\n" $0 }
  END { flush() }
' "$SPEC/TASKS.md")"
if [ -n "$tasks_report" ]; then
  while IFS= read -r line; do fail "$line"; done <<< "$tasks_report"
fi
task_count="$(grep -c '^### T-' "$SPEC/TASKS.md" || true)"

# PROGRESS rows: | task | status | evidence | measured | notes |
progress_report="$(awk -F'|' '
  /^\| *T-/ {
    st = $3; gsub(/^ +| +$/, "", st); gsub(/`/, "", st)
    if ((st == "merged" || st == "open-green") && $4 !~ /https?:\/\//) {
      t = $2; gsub(/^ +| +$/, "", t)
      printf "PROGRESS row %s has status %s without an evidence link\n", t, st
    }
  }
  /^- \*\*M[0-9]+\*\*.*claimed/ && !/not claimed/ && !/https?:\/\// { printf "PROGRESS gate line claims a gate without a proof link: %s\n", $0 }
' "$SPEC/PROGRESS.md")"
if [ -n "$progress_report" ]; then
  while IFS= read -r line; do fail "$line"; done <<< "$progress_report"
fi

# Placeholders, once the owner decisions are taken.
if grep -q '^Status: decided' "$SPEC/DECISIONS.md"; then
  left="$(grep -n '{{' "$SPEC"/DECISIONS.md "$SPEC"/SPEC.md "$SPEC"/TASKS.md "$SPEC"/PROGRESS.md AGENTS.md README.md 2>/dev/null || true)"
  if [ -n "$left" ]; then
    fail "DECISIONS.md says 'Status: decided' but placeholders are left:"
    printf '%s\n' "$left" | sed 's/^/  /' >&2
  fi
  mode="decided: placeholders checked"
else
  mode="DECISIONS.md is still open: placeholders not checked"
fi

if [ "$status" -eq 0 ]; then echo "check-spec: ok ($task_count task(s); $mode)"; fi
exit "$status"
