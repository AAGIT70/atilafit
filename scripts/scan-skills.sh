#!/usr/bin/env bash
# Scan every AI-agent skill in this repository with NVIDIA SkillSpector.
#
# A "skill" is any directory that contains a SKILL.md (or skill.md) file.
# Each one is scanned independently with static analysis only (--no-llm),
# so nothing in the skill is sent to an LLM provider. Dependency manifests
# found inside a skill are still looked up against OSV.dev (see docs/SKILLSPECTOR.md).
#
# Usage:
#   scripts/scan-skills.sh                 # scan the repo, reports in skillspector-reports/
#   scripts/scan-skills.sh path/to/skill   # scan one skill directory (or a URL / zip)
#
# Reviewed baselines: if .skillspector/baselines/<skill-dir-name>.yaml exists it is
# passed as --baseline, and the suppressed findings are still printed. Generate one
# only after reading every finding, with:
#   skillspector baseline .claude/skills/<name> --no-llm \
#     -o .skillspector/baselines/<name>.yaml --reason "..."
#
# Exit codes follow SkillSpector: 0 = all skills scored <= 50, 1 = at least one
# skill scored > 50 or a strict gate fired, 2 = scanner error.
set -u

REPORT_DIR="${SKILLSPECTOR_REPORT_DIR:-skillspector-reports}"
BASELINE_DIR="${SKILLSPECTOR_BASELINE_DIR:-.skillspector/baselines}"
EXTRA_ARGS=(--no-llm ${SKILLSPECTOR_EXTRA_ARGS:-})

if ! command -v skillspector >/dev/null 2>&1; then
  echo "skillspector is not installed. Install it with one of:" >&2
  echo "  uv tool install git+https://github.com/NVIDIA/skillspector.git" >&2
  echo "  pip install git+https://github.com/NVIDIA/skillspector.git" >&2
  exit 2
fi

mkdir -p "$REPORT_DIR"

if [ "$#" -gt 0 ]; then
  targets=("$@")
else
  mapfile -t targets < <(
    find . \( -path ./.git -o -path ./node_modules -o -path "./$REPORT_DIR" \) -prune -o \
      \( -iname SKILL.md \) -print | xargs -r -n1 dirname | sort -u
  )
fi

if [ "${#targets[@]}" -eq 0 ]; then
  echo "No skills found (no SKILL.md anywhere in the repository). Nothing to scan."
  exit 0
fi

skillspector --version 2>/dev/null | head -1
echo "Scanning ${#targets[@]} skill(s)..."
worst=0
for t in "${targets[@]}"; do
  name="$(basename "$t" | sed 's/[^A-Za-z0-9._-]/_/g')"
  echo
  echo "=== $t ==="
  args=("${EXTRA_ARGS[@]}")
  if [ -f "$BASELINE_DIR/$name.yaml" ]; then
    echo "(reviewed baseline applied: $BASELINE_DIR/$name.yaml; suppressed findings are listed below)"
    args+=(--baseline "$BASELINE_DIR/$name.yaml" --show-suppressed)
  fi
  skillspector scan "$t" "${args[@]}"
  rc=$?
  skillspector scan "$t" "${args[@]}" --format sarif --output "$REPORT_DIR/$name.sarif" >/dev/null 2>&1
  skillspector scan "$t" "${args[@]}" --format json  --output "$REPORT_DIR/$name.json"  >/dev/null 2>&1
  echo "--- exit code: $rc (reports: $REPORT_DIR/$name.{sarif,json})"
  [ "$rc" -gt "$worst" ] && worst=$rc
done

echo
if [ "$worst" -eq 0 ]; then
  echo "All skills passed (score <= 50)."
elif [ "$worst" -eq 1 ]; then
  echo "At least one skill scored above 50 or tripped a strict gate. Review the reports above." >&2
else
  echo "SkillSpector reported an error on at least one skill." >&2
fi
exit "$worst"
