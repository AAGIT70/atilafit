This directory is copied unmodified from the Microsoft `playwright-cli`
repository (`skills/playwright-cli/`, upstream commit b85c7a7, 2026-09-28),
licensed under the Apache License 2.0: https://github.com/microsoft/playwright-cli
It is the same location and content that `playwright-cli install --skills` writes.

Purpose: lets Claude Code drive a real browser through the `playwright-cli`
command: open pages, click, fill forms, take screenshots, record video, run
Playwright tests, mock network requests, and save or restore cookies and
local storage.

Requirements: Node.js 18+, and the CLI installed with
`npm install -g @playwright/cli@latest`. Without the CLI the skill does nothing.

What this skill really grants, read before relying on it:
- Its frontmatter pre-approves the `playwright-cli` command and the Playwright
  package runner commands, so Claude Code runs them without a permission
  prompt once the skill is active.
- Those commands can execute arbitrary JavaScript inside the browser page
  (`eval`, `run-code`), upload local files to web pages, and write browser
  state (cookies, tokens) to files on disk.
- One reference file shows attaching screenshots to GitHub pull requests with
  the `gh` CLI, which uploads files to GitHub.

SkillSpector v2.12.0 static scan: 80/100, HIGH, DO_NOT_INSTALL before review.
Every finding was read at its source line. None is malicious; all describe the
documented behaviour above or are scanner false positives:
- 2x "incomplete referenced artifact" (HIGH): the scanner could not fully parse
  references/pr-attachments.md. Read manually: gh pull-request attachment docs
  and a CI snippet that comments failure screenshots on a PR. Legitimate.
- 1x "memory manipulation" (HIGH): the sentence tells you to delete saved
  browser-state files after use. Security hygiene advice, false positive.
- 12x "unpinned package runner" (MEDIUM): the Playwright test runner is invoked
  through the package runner without a version suffix. Standard Playwright
  invocation; playwright is Microsoft's own package.
- 1x "external transmission" (MEDIUM): a request-mocking example that uses
  example.com. False positive.
- 1x "session persistence" (MEDIUM): the documented state-save feature.

These findings are suppressed by the reviewed baseline at
.skillspector/baselines/playwright-cli.yaml, accepted by the repository owner
on 2026-10-10. With it the score is 0/100 and only new findings will fail CI.
If the upstream skill is updated, regenerate the baseline only after reading
the new findings.
