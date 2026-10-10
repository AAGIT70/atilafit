# SkillSpector setup

[NVIDIA SkillSpector](https://github.com/NVIDIA/skillspector) is a security
scanner for AI-agent skills (Claude Code, Codex CLI, Gemini CLI, MCP servers).
It answers one question before you install a skill: is it safe? It checks for
prompt injection, data exfiltration, privilege escalation and supply-chain
problems, and returns a 0-100 risk score with a recommendation of
`SAFE`, `CAUTION` or `DO_NOT_INSTALL`.

This repository currently contains no skills of its own. The setup below is in
place so that the moment a skill is added or installed, it gets scanned.

## What is set up

| Piece | Purpose |
|---|---|
| `scripts/scan-skills.sh` | Finds every directory with a `SKILL.md` and scans each one. Writes SARIF and JSON reports to `skillspector-reports/`. Works locally and in CI. |
| `.github/workflows/skillspector.yml` | Runs the script on every push or pull request that touches a skill, on demand, and weekly. Fails the job if any skill scores above 50. Reports are uploaded as a workflow artifact. |
| `.claude/skills/skill-inspector/` | NVIDIA's own Claude Code skill. In Claude Code you can ask "is this skill safe to install?" and it runs SkillSpector plus a source review and gives an `APPROVE` / `CAUTION` / `REJECT` verdict. |

## Install locally

Requires Python 3.12 or newer.

```bash
# with uv (recommended)
uv tool install "git+https://github.com/NVIDIA/skillspector.git@v2.12.0"

# or with pip
pip install "git+https://github.com/NVIDIA/skillspector.git@v2.12.0"

skillspector --version
```

## Scan a skill before installing it

```bash
# a GitHub repo, a local folder, a zip, or a single SKILL.md
skillspector scan https://github.com/someone/their-skill --no-llm
skillspector scan ./downloaded-skill/ --no-llm
skillspector scan ./skill.zip --no-llm

# machine-readable output
skillspector scan ./downloaded-skill/ --no-llm --format json --output report.json
```

Rule of thumb (from NVIDIA's skill-inspector guidance): `SAFE` means install,
`CAUTION` means read the findings first, `DO_NOT_INSTALL` means do not install.

## Scan everything in this repo

```bash
scripts/scan-skills.sh
```

## About `--no-llm`

Everything here runs with `--no-llm`, which is static analysis only. Nothing
from the scanned skill is sent to an LLM. One exception: if a skill declares
dependencies (for example a `requirements.txt`), SkillSpector looks those
package names up on OSV.dev to check for known vulnerabilities.

If you want the deeper LLM-based semantic review, drop `--no-llm` and set a
provider, for example:

```bash
export SKILLSPECTOR_PROVIDER=anthropic
export ANTHROPIC_API_KEY=...   # never commit this
skillspector scan ./downloaded-skill/
```

Other supported providers include `openai`, `nv_build`, `ollama`, `bedrock`,
`azure_openai`, `gemini` and the local `claude_cli` login. Run
`skillspector scan --help` for the full list and the variables each needs.

## Reviewed baselines

Some legitimate skills score above the gate because the scanner reacts to
words rather than intent. Example: the Microsoft `playwright-cli` skill scores
80 because it documents saving browser cookies to a file and running
`npx playwright`. After reading every finding at its source line, accept them
with a baseline so that only new findings fail CI:

```bash
skillspector baseline .claude/skills/<name> --no-llm \
  -o .skillspector/baselines/<name>.yaml --reason "why these are acceptable"
```

`scripts/scan-skills.sh` picks the baseline up automatically by skill folder
name and still prints the suppressed findings in the log. Write the reasoning
in the skill's `NOTICE.md`. Never generate a baseline without reading the
findings first, that would defeat the scanner.

Current baselines:

| Skill | Suppressed | Why |
|---|---|---|
| `playwright-cli` | 18 | Documented browser-automation behaviour and false positives, see its `NOTICE.md`. Accepted by the repository owner on 2026-10-10. |

## Upgrading

The version is pinned to `v2.12.0` in the workflow and in this file. To
upgrade, check the release notes at
https://github.com/NVIDIA/skillspector/releases, then update the tag in
`.github/workflows/skillspector.yml`.
